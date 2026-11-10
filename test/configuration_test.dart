import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  test('balanced defaults are bounded and stable', () {
    const config = LiquidGlassConfig();
    expect(config.blurSigma, inInclusiveRange(0, 30));
    expect(config.refractionStrength, inInclusiveRange(0, 0.12));
    expect(config.maxDisplacement, lessThanOrEqualTo(64));
    expect(config.refractiveIndex, inInclusiveRange(1, 2));
    expect(config.cornerSmoothing, inInclusiveRange(0, 1));
    expect(config.innerShadow, inInclusiveRange(0, 1));
    expect(config.roughness, inInclusiveRange(0, 1));
    expect(config.transmission, inInclusiveRange(0, 1));
    expect(config.abbeNumber, greaterThanOrEqualTo(5));
    expect(config.coatRefractiveIndex, greaterThanOrEqualTo(1));
    expect(config.motionStrength, inInclusiveRange(0, 3));
    expect(config.quality, LiquidGlassQuality.balanced);
  });

  test('copyWith is immutable and preserves unspecified values', () {
    const original = LiquidGlassConfig();
    final changed = original.copyWith(
      blurSigma: 12,
      tint: Colors.blue.withValues(alpha: 0.2),
      refractiveIndex: 1.33,
      roughness: 0.4,
      thinFilmThickness: 480,
      motionStrength: 1.4,
    );
    expect(original.blurSigma, 5.5);
    expect(changed.blurSigma, 12);
    expect(changed.refractionStrength, original.refractionStrength);
    expect(changed.refractiveIndex, 1.33);
    expect(changed.roughness, 0.4);
    expect(changed.thinFilmThickness, 480);
    expect(changed.motionStrength, 1.4);
    expect(changed.absorptionColor, original.absorptionColor);
    expect(changed, isNot(original));
  });

  test('presets make distinct quality tradeoffs', () {
    const regular = LiquidGlassConfig.regular();
    const clear = LiquidGlassConfig.clear();
    const crystal = LiquidGlassConfig.crystal();
    const frosted = LiquidGlassConfig.frosted();
    const performance = LiquidGlassConfig.performance();
    expect(crystal.refractionStrength, greaterThan(frosted.refractionStrength));
    expect(frosted.blurSigma, greaterThan(crystal.blurSigma));
    expect(performance.quality, LiquidGlassQuality.performance);
    expect(regular, const LiquidGlassConfig());
    expect(clear, crystal);
    expect(clear.borderWidth, 0);
    expect(clear.edgeWidth, lessThan(0.1));
    expect(clear.roughness, lessThan(regular.roughness));
    expect(clear.transmission, greaterThan(regular.transmission));
    expect(frosted.scatteringStrength, greaterThan(regular.scatteringStrength));
    expect(clear.dispersionStrength, greaterThan(regular.dispersionStrength));
    expect(clear.motionStrength, greaterThan(regular.motionStrength));
  });
}
