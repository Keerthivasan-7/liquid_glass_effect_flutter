import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

void main() {
  test('rounded radius is clamped for small surfaces', () {
    const shape = LiquidGlassShape.roundedRectangle(borderRadius: 80);
    expect(shape.resolvedRadius(const Size(40, 20)), 10);
  });

  test('all supported shape paths contain their center', () {
    const size = Size(120, 80);
    const center = Offset(60, 40);
    const shapes = <LiquidGlassShape>[
      LiquidGlassShape.roundedRectangle(),
      LiquidGlassShape.capsule(),
      LiquidGlassShape.circle(),
    ];
    for (final shape in shapes) {
      expect(shape.pathFor(size).contains(center), isTrue);
    }
  });

  test('shape shader identifiers stay stable', () {
    expect(const LiquidGlassShape.roundedRectangle().shaderValue, 0);
    expect(const LiquidGlassShape.capsule().shaderValue, 1);
    expect(const LiquidGlassShape.circle().shaderValue, 2);
  });
}
