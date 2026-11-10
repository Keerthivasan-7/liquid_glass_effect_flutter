import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';
import 'package:liquid_glass_effect_flutter/src/rendering/capture_footprint.dart';

void main() {
  test('quality and anisotropy envelopes contain the emitted sample stencils',
      () {
    for (final quality in LiquidGlassQuality.values) {
      for (final anisotropy in <double>[-0.95, 0, 0.95]) {
        for (final rotation in <double>[0, 0.125, 0.25, 0.375, 1]) {
          for (final size in <Size>[
            const Size(1, 1),
            const Size(2, 1000),
            const Size(1000, 2),
            const Size(127.5, 81.25),
            const Size(1920, 1080)
          ]) {
            final config = LiquidGlassConfig(
              maxDisplacement: 64,
              chromaticAberration: 0.01,
              blurSigma: 30,
              roughness: 1,
              thickness: 2,
              scatteringStrength: 1,
              coatRoughness: 1,
              anisotropy: anisotropy,
              anisotropyRotation: rotation,
              quality: quality,
            );
            final footprint = liquidGlassCaptureFootprint(
                config: config, surfaceSize: size, capturePixelRatio: 0.65);
            final shortest = math.max(1.0, size.shortestSide);
            final scatter =
                math.min(30 + shortest * 0.7 + shortest * 0.08, 32.0);
            final reflection = math.min(24.0, 0.35 + shortest * 0.275);
            for (var direction = 0; direction < 16; direction += 1) {
              final angle = direction * math.pi / 8;
              final axis = Offset(math.cos(angle), math.sin(angle));
              final displaced = axis * (64 * 1.3);
              for (final tap in _stencil(scatter, quality)) {
                final sample = (displaced + axis * (0.01 * shortest)) * 1.09 +
                    _anisotropic(tap, anisotropy, rotation);
                expect(sample.distance,
                    lessThanOrEqualTo(footprint.transmissionReach + 0.000001));
              }
              for (final tap in _stencil(reflection, quality)) {
                final sample = displaced * 0.85 +
                    axis * (scatter * 0.24) +
                    _anisotropic(tap, anisotropy, rotation);
                expect(sample.distance,
                    lessThanOrEqualTo(footprint.reflectionReach + 0.000001));
              }
            }
            expect(footprint.logicalPadding,
                greaterThan(footprint.transmissionReach));
            expect(footprint.logicalPadding,
                greaterThan(footprint.reflectionReach));
          }
        }
      }
    }
  });

  test('effective DPR and quality scale reserve a complete captured texel', () {
    for (final dpr in <double>[1, 1.25, 2.625, 3]) {
      for (final qualityScale in <double>[0.25, 0.65, 1]) {
        final ratio = dpr * qualityScale;
        final footprint = liquidGlassCaptureFootprint(
            config: const LiquidGlassConfig(),
            surfaceSize: const Size(127.5, 81.25),
            capturePixelRatio: ratio);
        final reach =
            math.max(footprint.transmissionReach, footprint.reflectionReach);
        expect((footprint.logicalPadding - reach - 1) * ratio,
            closeTo(1, 0.000001));
        expect(footprint.capturePixelPadding,
            closeTo(footprint.logicalPadding * ratio, 0.000001));
        final surface = const Rect.fromLTWH(100.125, 80.75, 127.5, 81.25);
        final bounds = footprint.boundsFor(surface);
        expect(bounds.left, lessThan(surface.left - reach));
        expect(bounds.bottom, greaterThan(surface.bottom + reach));
      }
    }
  });

  test('zero displacement and blur still cover the reflection stencil', () {
    final config = const LiquidGlassConfig().copyWith(
        maxDisplacement: 0,
        chromaticAberration: 0,
        blurSigma: 0,
        roughness: 0,
        scatteringStrength: 0,
        coatRoughness: 0,
        quality: LiquidGlassQuality.ultra);
    final footprint = liquidGlassCaptureFootprint(
        config: config,
        surfaceSize: const Size(100, 100),
        capturePixelRatio: 1);
    expect(footprint.transmissionReach, 0);
    expect(footprint.reflectionReach, greaterThan(0));
    expect(footprint.logicalPadding, greaterThan(2));
  });
}

Iterable<Offset> _stencil(double radius, LiquidGlassQuality quality) sync* {
  yield Offset.zero;
  if (quality == LiquidGlassQuality.performance || radius < 0.25) return;
  for (final fraction in <double>[
    0.38,
    if (quality == LiquidGlassQuality.ultra) 0.92
  ]) {
    for (var angle = 0; angle < 8; angle += 1) {
      yield Offset(
              math.cos(angle * math.pi / 4), math.sin(angle * math.pi / 4)) *
          (radius * fraction);
    }
  }
}

Offset _anisotropic(Offset value, double amount, double rotation) {
  Offset rotate(Offset p, double angle) => Offset(
      p.dx * math.cos(angle) - p.dy * math.sin(angle),
      p.dx * math.sin(angle) + p.dy * math.cos(angle));
  final angle = rotation * math.pi * 2;
  final local = rotate(value, -angle);
  final stretch = 1 + amount.abs() * 1.75;
  return rotate(
      amount >= 0
          ? Offset(local.dx * stretch, local.dy / stretch)
          : Offset(local.dx / stretch, local.dy * stretch),
      angle);
}
