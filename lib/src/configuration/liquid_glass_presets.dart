// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'liquid_glass_config.dart';

/// Predefined optical material configurations optimized for dark mode
/// and adaptive environments.
abstract final class LiquidGlassPresets {
  /// Dark-mode optimized version of [LiquidGlassConfig.regular].
  ///
  /// Uses a deeper, charcoal-tinted refraction and slightly increased
  /// inner shadow for distinct separation on dark backgrounds.
  static const LiquidGlassConfig regularDark = LiquidGlassConfig(
    blurSigma: 6.5,
    refractionStrength: 0.048,
    fresnelStrength: 0.65,
    specularStrength: 0.55,
    chromaticAberration: 0.00012,
    roughness: 0.20,
    transmission: 0.92,
    thickness: 0.82,
    absorptionColor: Color(0xFF0F172A),
    absorptionStrength: 0.35,
    scatteringStrength: 0.06,
    dispersionStrength: 0.10,
    innerShadow: 0.28,
    tint: Color(0x280B1120),
    lightColor: Color(0xFFD4E2F4),
  );

  /// Dark-mode optimized version of [LiquidGlassConfig.clear].
  static const LiquidGlassConfig clearDark = LiquidGlassConfig(
    blurSigma: 2.0,
    refractionStrength: 0.065,
    fresnelStrength: 0.82,
    specularStrength: 0.78,
    chromaticAberration: 0.00018,
    roughness: 0.05,
    transmission: 0.97,
    thickness: 0.92,
    absorptionColor: Color(0xFF0A0F1D),
    absorptionStrength: 0.15,
    scatteringStrength: 0.02,
    dispersionStrength: 0.22,
    innerShadow: 0.22,
    tint: Color(0x18050914),
    quality: LiquidGlassQuality.ultra,
  );

  /// Dark-mode optimized version of [LiquidGlassConfig.frosted].
  ///
  /// Features deeper obsidian tone with higher blur for enhanced
  /// legibility over complex dark surfaces.
  static const LiquidGlassConfig frostedDark = LiquidGlassConfig(
    blurSigma: 13.0,
    refractionStrength: 0.030,
    fresnelStrength: 0.50,
    specularStrength: 0.38,
    roughness: 0.50,
    transmission: 0.82,
    thickness: 0.72,
    absorptionColor: Color(0xFF080C16),
    absorptionStrength: 0.45,
    scatteringStrength: 0.32,
    innerShadow: 0.32,
    edgeWidth: 0.075,
    tint: Color(0x40030712),
  );

  /// Selects either light [regular] or [regularDark] based on brightness.
  static LiquidGlassConfig adaptive(
    Brightness brightness, {
    LiquidGlassConfig light = const LiquidGlassConfig.regular(),
    LiquidGlassConfig dark = regularDark,
  }) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Convenience extensions on [LiquidGlassConfig] for mode adjustments.
extension LiquidGlassConfigModeExtension on LiquidGlassConfig {
  /// Returns a dark-themed variation of this configuration.
  LiquidGlassConfig toDark() {
    return copyWith(
      tint: const Color(0x30050A18),
      absorptionColor: const Color(0xFF080D1A),
      innerShadow: (innerShadow * 1.35).clamp(0.0, 1.0),
      specularStrength: (specularStrength * 0.9).clamp(0.0, 2.0),
      lightColor: const Color(0xFFD0E0F8),
    );
  }
}
