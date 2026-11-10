import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';

import '../configuration/liquid_glass_config.dart';

/// Conservative sampling envelope for the capture renderer, in logical pixels.
///
/// The envelope covers the largest coordinate excursion used by transmission
/// and reflection sampling, including the quality stencil, anisotropy,
/// chromatic offset, and one captured texel for filtered texture sampling.
@immutable
class LiquidGlassCaptureFootprint {
  const LiquidGlassCaptureFootprint({
    required this.logicalPadding,
    required this.transmissionReach,
    required this.reflectionReach,
    required this.capturePixelRatio,
  });

  /// Padding required around a glass surface before clipping to its scope.
  final double logicalPadding;

  /// Maximum reach from the surface edge for transmitted color samples.
  final double transmissionReach;

  /// Maximum reach from the surface edge for environment/reflection samples.
  final double reflectionReach;

  /// Effective raster scale used by `OffsetLayer.toImageSync`.
  final double capturePixelRatio;

  /// The same conservative guard expressed in captured texture pixels.
  double get capturePixelPadding => logicalPadding * capturePixelRatio;

  /// Returns [surfaceBounds] expanded by this footprint.
  Rect boundsFor(Rect surfaceBounds) => surfaceBounds.inflate(logicalPadding);
}

/// Computes the capture padding required by the current shader contract.
///
/// [surfaceSize] is the glass shape's logical-pixel size. [capturePixelRatio]
/// is the effective image scale (`devicePixelRatio * qualityScale`), not just
/// the device's DPR. All sampling distances are first calculated in logical
/// pixels because the shaders express displacement and scatter in that space.
LiquidGlassCaptureFootprint liquidGlassCaptureFootprint({
  required LiquidGlassConfig config,
  required Size surfaceSize,
  required double capturePixelRatio,
}) {
  assert(capturePixelRatio > 0);

  final shortest = math.max(
    1.0,
    math.min(surfaceSize.width, surfaceSize.height),
  );
  final anisotropyStretch =
      1.0 + config.anisotropy.abs().clamp(0.0, 0.95) * 1.75;

  // refracted_offset caps the vector magnitude, then the edge profile scales
  // it by at most 1.3. The legacy chromatic offset is a separate screen-space
  // vector and is not covered by maxDisplacement.
  final refractedReach = config.maxDisplacement * 1.3;
  final chromaticReach = config.chromaticAberration * shortest;

  // Keep these equations in sync with scatter_radius and reflection_radius in
  // both fragment shaders. Their quality stencil reaches 0, 0.38, or 0.92 of
  // its radius before anisotropy stretching.
  final scatterRadius = math.min(
    config.blurSigma +
        config.roughness *
            config.roughness *
            shortest *
            0.35 *
            config.thickness +
        config.scatteringStrength * shortest * 0.08,
    32.0,
  );
  final reflectionRadius = math.min(
    24.0,
    0.35 +
        config.roughness * config.roughness * shortest * 0.24 +
        config.coatRoughness * shortest * 0.035,
  );
  final stencilFraction = switch (config.quality) {
    LiquidGlassQuality.performance => 0.0,
    LiquidGlassQuality.balanced => 0.38,
    LiquidGlassQuality.ultra => 0.92,
  };
  final transmissionStencil =
      scatterRadius * stencilFraction * anisotropyStretch;
  final reflectionStencil =
      reflectionRadius * stencilFraction * anisotropyStretch;

  final transmissionReach =
      refractedReach + chromaticReach + transmissionStencil;

  // reflection_offset combines 0.45..0.85 of the refracted vector with a
  // light-directed 0.24 * scatterRadius offset, then applies its own stencil.
  final reflectionReach =
      refractedReach * 0.85 + scatterRadius * 0.24 + reflectionStencil;

  // One logical pixel covers the surface raster fringe; one captured texel
  // covers the filtered texture footprint at the effective DPR/quality scale.
  final rasterGuard = 1.0 + 1.0 / capturePixelRatio;
  final logicalPadding =
      math.max(transmissionReach, reflectionReach) + rasterGuard;

  return LiquidGlassCaptureFootprint(
    logicalPadding: logicalPadding,
    transmissionReach: transmissionReach,
    reflectionReach: reflectionReach,
    capturePixelRatio: capturePixelRatio,
  );
}
