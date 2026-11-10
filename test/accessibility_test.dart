import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  testWidgets(
      'hover and press reuse a static capture through the full scale animation',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;
    await tester.pumpWidget(MaterialApp(
        home: LiquidGlassScope(
      onDiagnosticsChanged: (value) => diagnostics = value,
      background: const ColoredBox(color: Colors.blue),
      child: const Center(
          child: LiquidGlass(
              width: 360,
              height: 180,
              interactive: true,
              config: LiquidGlassConfig(renderer: LiquidGlassRenderer.capture),
              child: SizedBox())),
    )));
    await tester.pumpAndSettle();
    final captures = diagnostics!.captureCount;
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(LiquidGlass)));
    await tester.pumpAndSettle();
    expect(diagnostics!.captureCount, captures);
    await mouse.down(tester.getCenter(find.byType(LiquidGlass)));
    await tester.pumpAndSettle();
    await mouse.up();
    await tester.pumpAndSettle();
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(diagnostics!.captureCount, captures);
  });

  testWidgets(
      'reduced transparency uses an opaque fallback without capture or blur',
      (tester) async {
    LiquidGlassRenderPath? path;
    LiquidGlassDiagnostics? diagnostics;
    await tester.pumpWidget(MaterialApp(
      home: LiquidGlassScope(
        onDiagnosticsChanged: (value) => diagnostics = value,
        background: const ColoredBox(color: Colors.red),
        child: Center(
            child: LiquidGlass(
          width: 180,
          height: 100,
          config: const LiquidGlassConfig(
              renderer: LiquidGlassRenderer.capture, animateLight: true),
          accessibility: const LiquidGlassAccessibilityPolicy(
              reduceTransparency: true, opaqueColor: Color(0x80223344)),
          onRenderPathChanged: (value) => path = value,
          child: const Column(children: <Widget>[
            Text('Readable', style: TextStyle(fontSize: 14)),
            Icon(Icons.add)
          ]),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(path, LiquidGlassRenderPath.fallback);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(diagnostics!.captureCount, 0);
    expect(diagnostics!.activeSurfaceCount, 0);
    expect(diagnostics!.retainedBytes, 0);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is ColoredBox && widget.color == const Color(0xFF223344)),
        findsOneWidget);
    expect(
        DefaultTextStyle.of(tester.element(find.text('Readable'))).style.color,
        Colors.white);
    expect(IconTheme.of(tester.element(find.byIcon(Icons.add))).color,
        Colors.white);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('high contrast follows MediaQuery and accepts an app override',
      (tester) async {
    Widget build(bool? override) => MaterialApp(
            home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: Center(
              child: LiquidGlass(
            width: 180,
            height: 100,
            config:
                const LiquidGlassConfig(renderer: LiquidGlassRenderer.fallback),
            accessibility:
                LiquidGlassAccessibilityPolicy(highContrast: override),
            child: const Text('Contrast'),
          )),
        ));
    await tester.pumpWidget(build(null));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpWidget(build(false));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('switching to reduced transparency retires the captured image',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;
    LiquidGlassRenderPath? path;
    Widget build(bool reduced) => MaterialApp(
            home: LiquidGlassScope(
          onDiagnosticsChanged: (value) => diagnostics = value,
          background: const ColoredBox(color: Colors.blue),
          child: Center(
              child: LiquidGlass(
            width: 180,
            height: 100,
            config:
                const LiquidGlassConfig(renderer: LiquidGlassRenderer.capture),
            accessibility:
                LiquidGlassAccessibilityPolicy(reduceTransparency: reduced),
            onRenderPathChanged: (value) => path = value,
            child: const Text('Content'),
          )),
        ));
    await tester.pumpWidget(build(false));
    await tester.pumpAndSettle();
    expect(path, LiquidGlassRenderPath.capture);
    expect(diagnostics!.estimatedBytes, greaterThan(0));
    await tester.pumpWidget(build(true));
    await tester.pumpAndSettle();
    expect(path, LiquidGlassRenderPath.fallback);
    expect(diagnostics!.activeSurfaceCount, 0);
    expect(diagnostics!.retainedBytes, 0);
    expect(diagnostics!.retiredImageCount, 0);
  });

  testWidgets(
      'motion preferences leave no light or pointer-settle ticker running',
      (tester) async {
    for (var mode = 0; mode < 3; mode += 1) {
      LiquidGlassDiagnostics? diagnostics;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            disableAnimations: mode == 0, accessibleNavigation: mode == 1),
        child: LiquidGlassScope(
          onDiagnosticsChanged: (value) => diagnostics = value,
          background: const ColoredBox(color: Colors.green),
          child: Center(
              child: LiquidGlass(
            width: 180,
            height: 100,
            interactive: true,
            config: const LiquidGlassConfig(
                renderer: LiquidGlassRenderer.capture, animateLight: true),
            accessibility:
                LiquidGlassAccessibilityPolicy(reduceMotion: mode == 2),
            child: const Text('Still'),
          )),
        ),
      )));
      await tester.pumpAndSettle();
      final captures = diagnostics!.captureCount;
      final mouse =
          await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await mouse.addPointer(
          location: tester.getCenter(find.byType(LiquidGlass)));
      await mouse.down(tester.getCenter(find.byType(LiquidGlass)));
      await mouse.up();
      await mouse.removePointer();
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(diagnostics!.captureCount, captures);
    }
  });

  testWidgets(
      'keyboard focus paints a ring and preserves child activation and semantics',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final focus = FocusNode();
    try {
      const boundary = ValueKey<String>('focus-pixels');
      var activations = 0;
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: RepaintBoundary(
        key: boundary,
        child: SizedBox(
            width: 220,
            height: 100,
            child: ColoredBox(
              color: Colors.black,
              child: LiquidGlass(
                interactive: true,
                config: const LiquidGlassConfig(
                    renderer: LiquidGlassRenderer.fallback),
                child: Center(
                    child: TextButton(
                        focusNode: focus,
                        onPressed: () => activations += 1,
                        child: const Text('Activate'))),
              ),
            )),
      ))));
      await tester.pumpAndSettle();
      final before = await _pixel(tester, boundary, 3, 50);
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      final after = await _pixel(tester, boundary, 3, 50);
      expect(after, isNot(before));
      expect(after, <int>[255, 255, 255, 255]);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activations, 1);
      final node = tester.getSemantics(find.byType(TextButton));
      expect(node.getSemanticsData().label, 'Activate');
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      SemanticsNode root = node;
      while (root.parent != null) {
        root = root.parent!;
      }
      var labels = 0;
      void visit(SemanticsNode current) {
        if (current.getSemanticsData().label == 'Activate') labels += 1;
        current.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(root);
      expect(labels, 1);
    } finally {
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      semantics.dispose();
    }
  });

  testWidgets(
      'large text keeps its semantics and actions on the opaque surface',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var activated = false;
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(
            child: LiquidGlass(
          width: 280,
          height: 180,
          semanticLabel: 'Floating tools',
          accessibility:
              const LiquidGlassAccessibilityPolicy(reduceTransparency: true),
          child: Center(
              child: TextButton(
                  onPressed: () => activated = true,
                  child: const Text('Open'))),
        )),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          tester
              .getSemantics(find.byType(LiquidGlass))
              .getSemanticsData()
              .label,
          contains('Floating tools'));
      await tester.tap(find.text('Open'));
      expect(activated, isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    }
  });
}

Future<List<int>> _pixel(WidgetTester tester, Key key, int x, int y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      return List<int>.generate(4, (c) => data[(y * image.width + x) * 4 + c]);
    } finally {
      image.dispose();
    }
  });
  return pixels!;
}
