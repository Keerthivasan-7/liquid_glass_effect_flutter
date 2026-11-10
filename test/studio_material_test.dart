import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

import 'support/renderer_fixture.dart';

Future<Uint8List> _pixels(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  test('lighting passes through neutral and rejects invalid measurements', () {
    final light = LiquidGlassLightingController();
    addTearDown(light.dispose);
    light.updateFromPointer(const Offset(55, 10), const Size(100, 20));
    expect(light.value.dx, closeTo(.1, 1e-10));
    light.updateFromTilt(pitch: 0, roll: 0);
    expect(light.value, Offset.zero);
    light.updateFromTilt(pitch: double.nan, roll: 1);
    light.updateFromPointer(
        const Offset(double.infinity, 0), const Size(20, 20));
    expect(light.value, Offset.zero);
    light.updateFromTilt(pitch: .2, roll: -.1);
    expect(light.value.distance, lessThan(.25));
  });

  testWidgets('two capsules shade the gap once and leave its action unclaimed',
      (tester) async {
    const boundary = ValueKey('cluster');
    LiquidGlassRenderPath? path;
    LiquidGlassDiagnostics? stats;
    var hits = 0;
    Future<void> scene(double blend) async {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: SizedBox(
        width: 260,
        height: 120,
        child: RepaintBoundary(
            key: boundary,
            child: LiquidGlassScene(
              qualityScale: 1,
              pixelRatio: 1,
              content: const ColoredBox(color: Color(0xff202020)),
              onDiagnosticsChanged: (d) => stats = d,
              glass: LiquidGlassCluster(
                  blendRadius: blend,
                  config: coordinateGlassConfig.copyWith(
                      tint: const Color(0xffefefef)),
                  onRenderPathChanged: (p) => path = p,
                  members: [
                    for (var i = 0; i < 2; i++)
                      LiquidGlassMember(
                          id: i,
                          bounds: Rect.fromLTWH(42 + i * 74, 36, 64, 48),
                          child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => hits++)),
                  ]),
            )),
      ))));
      await tester.pumpAndSettle();
    }

    await scene(0);
    final apart = await _pixels(tester, boundary);
    await scene(40);
    final joined = await _pixels(tester, boundary);
    final neck = (60 * 260 + 111) * 4;
    expect(path, LiquidGlassRenderPath.capture);
    expect(stats!.activeSurfaceCount, 1);
    expect(apart[neck], 32);
    expect(joined[neck] - apart[neck], greaterThan(15));
    expect(joined[(25 * 260 + 111) * 4], 32);
    final origin = tester.getTopLeft(find.byKey(boundary));
    await tester.tapAt(origin + const Offset(111, 60));
    expect(hits, 0);
    await tester.tapAt(origin + const Offset(74, 60));
    expect(hits, 1);
  });

  testWidgets('wave travels under a held pointer with fixed light then stops',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: RendererFixture(
      config: coordinateGlassConfig,
      interactive: true,
      backdrop: FixtureBackdrop.verticalStripes,
    )));
    await tester.pumpAndSettle();
    final key = RendererFixture.boundaryKey;
    final gesture = await tester.startGesture(
        tester.getTopLeft(find.byKey(key)) + const Offset(190, 150));
    await tester.pump();
    // Press scaling and pointer strength reach their resting values at 180ms.
    await tester.pump(const Duration(milliseconds: 210));
    final a = await _pixels(tester, key);
    await tester.pump(const Duration(milliseconds: 130));
    final b = await _pixels(tester, key);
    var changed = 0;
    for (var y = 110; y < 190; y++) {
      for (var x = 212; x < 268; x++) {
        final index = (y * 400 + x) * 4;
        if ((a[index] - b[index]).abs() > 2) changed++;
      }
    }
    expect(changed, greaterThan(10));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a second tap leaves the first wave at its own origin',
      (tester) async {
    Future<Uint8List> sample(bool firstTap) async {
      await tester.pumpWidget(MaterialApp(
          home: RendererFixture(
        key: ValueKey(firstTap),
        config: coordinateGlassConfig,
        interactive: true,
        backdrop: FixtureBackdrop.verticalStripes,
      )));
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(find.byKey(RendererFixture.boundaryKey));
      if (firstTap) await tester.tapAt(origin + const Offset(180, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final second = await tester.startGesture(origin + const Offset(265, 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      final result = await _pixels(tester, RendererFixture.boundaryKey);
      await second.up();
      await tester.pumpAndSettle();
      return result;
    }

    final single = await sample(false);
    final doubleTap = await sample(true);
    var changed = 0;
    // Inside the first wave's annulus, beyond the second wave's front.
    for (var y = 135; y < 165; y++) {
      for (var x = 119; x < 139; x++) {
        final index = (y * 400 + x) * 4;
        if ((doubleTap[index] - single[index]).abs() > 2) changed++;
      }
    }
    expect(changed, greaterThan(5));
  });

  testWidgets('glass button activates from the keyboard exactly once',
      (tester) async {
    var hits = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: LiquidGlassButton(
      accessibility: const LiquidGlassAccessibilityPolicy(reduceMotion: true),
      onPressed: () => hits++,
      child: const Text('Apply'),
    ))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(hits, 1);
  });
}
