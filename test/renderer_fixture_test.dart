import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

import 'support/renderer_fixture.dart';

void main() {
  testWidgets('moving-gradient analytical probe matches rendered pixels',
      (tester) async {
    for (final phase in <double>[0, 0.27, 0.5, 0.8, 1]) {
      await tester.pumpWidget(MaterialApp(
          home: RendererFixture(
              config: coordinateGlassConfig.copyWith(
                  renderer: LiquidGlassRenderer.fallback),
              backdrop: FixtureBackdrop.gradient,
              phase: phase)));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(RendererFixture.boundaryKey));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                  .buffer
                  .asUint8List();
          final expected = fixtureGradientColorAt(
              RendererFixture.size, phase, const Offset(200.5, 120.5));
          final channels = <double>[
            expected.r * 255,
            expected.g * 255,
            expected.b * 255
          ];
          for (var channel = 0; channel < 3; channel += 1) {
            expect(bytes[(120 * image.width + 200) * 4 + channel],
                closeTo(channels[channel], 2),
                reason: 'phase=$phase channel=$channel');
          }
        } finally {
          image.dispose();
        }
      });
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fixture preserves calibration coordinates on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LiquidGlassDiagnostics? diagnostics;
    await tester.pumpWidget(MaterialApp(
        home: RendererFixture(
            config: coordinateGlassConfig.copyWith(refractionStrength: 0),
            onDiagnostics: (value) => diagnostics = value)));
    await tester.pumpAndSettle();
    expect(diagnostics!.scopeSize, RendererFixture.size);
    expect(tester.getCenter(find.byType(LiquidGlass)), const Offset(180, 400));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(RendererFixture.boundaryKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        expect(image.width, 400);
        expect(image.height, 300);
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        final index = (150 * image.width + 200) * 4;
        expect(bytes[index], closeTo(128, 2));
        expect(bytes[index + 1], closeTo(128, 2));
        expect(bytes[index + 3], 255);
      } finally {
        image.dispose();
      }
    });
    await tester.pumpWidget(const SizedBox());
  });
}
