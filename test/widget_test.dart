import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  testWidgets('renders its foreground child over the fallback backdrop',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: <Widget>[
            ColoredBox(color: Colors.purple),
            Center(
              child: LiquidGlass(
                config:
                    LiquidGlassConfig(renderer: LiquidGlassRenderer.fallback),
                width: 180,
                height: 100,
                child: Text('Sharp child'),
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Sharp child'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(tester.getSize(find.byType(LiquidGlass)), const Size(180, 100));
  });

  testWidgets('responds to config and theme changes', (tester) async {
    Widget build(Brightness brightness, double blur) => MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Center(
            child: LiquidGlass(
              config: LiquidGlassConfig(
                blurSigma: blur,
                renderer: LiquidGlassRenderer.fallback,
              ),
              width: 140,
              height: 80,
              child: const Text('Content'),
            ),
          ),
        );
    await tester.pumpWidget(build(Brightness.light, 4));
    await tester.pumpWidget(build(Brightness.dark, 12));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('honors reduced animation settings without lifecycle errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LiquidGlass(
            config: LiquidGlassConfig(
              animateLight: true,
              renderer: LiquidGlassRenderer.fallback,
            ),
            width: 120,
            height: 64,
            child: SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scope separates background from sharp foreground',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScope(
          background: const ColoredBox(color: Colors.teal),
          child: const Center(
            child: LiquidGlass(
              config: LiquidGlassConfig(renderer: LiquidGlassRenderer.fallback),
              width: 160,
              height: 90,
              child: Text('Scoped child'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Scoped child'), findsOneWidget);
    expect(find.byType(LiquidGlassScope), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene exposes content and glass as separate planes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiquidGlassScene(
          content: ColoredBox(
            color: Colors.indigo,
            child: Center(child: Text('Scene content')),
          ),
          glass: Center(
            child: LiquidGlass(
              config: LiquidGlassConfig(
                renderer: LiquidGlassRenderer.fallback,
              ),
              width: 160,
              height: 80,
              child: Text('Glass overlay'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Scene content'), findsOneWidget);
    expect(find.text('Glass overlay'), findsOneWidget);
    expect(find.byType(LiquidGlassScope), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture is bounded and ignores overlay-only repaints',
      (tester) async {
    final contentColor = ValueNotifier<Color>(Colors.red);
    final overlayColor = ValueNotifier<Color>(Colors.white);
    final showGlass = ValueNotifier<bool>(true);
    LiquidGlassDiagnostics? diagnostics;

    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScene(
          onDiagnosticsChanged: (value) => diagnostics = value,
          content: ValueListenableBuilder<Color>(
            valueListenable: contentColor,
            builder: (context, color, _) => ColoredBox(color: color),
          ),
          glass: Stack(
            children: <Widget>[
              ValueListenableBuilder<Color>(
                valueListenable: overlayColor,
                builder: (context, color, _) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: showGlass,
                builder: (context, visible, _) => visible
                    ? const Center(
                        child: LiquidGlass(
                          config: LiquidGlassConfig(
                            renderer: LiquidGlassRenderer.capture,
                          ),
                          width: 120,
                          height: 70,
                          child: SizedBox(),
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initial = diagnostics!;
    expect(initial.captureCount, greaterThan(0));
    expect(initial.activeSurfaceCount, 1);
    expect(initial.captureRect.width, lessThan(800));
    expect(initial.captureRect.height, lessThan(600));
    expect(
      initial.estimatedBytes,
      initial.pixelSize.width.toInt() * initial.pixelSize.height.toInt() * 4,
    );

    overlayColor.value = Colors.black;
    await tester.pump();
    await tester.pump();
    expect(diagnostics!.captureCount, initial.captureCount);

    contentColor.value = Colors.blue;
    await tester.pump();
    await tester.pump();
    expect(diagnostics!.captureCount, greaterThan(initial.captureCount));

    showGlass.value = false;
    await tester.pumpAndSettle();
    expect(diagnostics!.activeSurfaceCount, 0);
    expect(diagnostics!.estimatedBytes, 0);
    expect(diagnostics!.captureRect, Rect.zero);

    await tester.pumpWidget(const SizedBox());
    contentColor.dispose();
    overlayColor.dispose();
    showGlass.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving a surface and changing quality refreshes its crop',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;

    Widget build(Alignment alignment, double qualityScale) => MaterialApp(
          home: SizedBox(
            width: 500,
            height: 400,
            child: LiquidGlassScope(
              pixelRatio: 1,
              qualityScale: qualityScale,
              onDiagnosticsChanged: (value) => diagnostics = value,
              background: const ColoredBox(color: Colors.deepPurple),
              child: Align(
                alignment: alignment,
                child: const LiquidGlass(
                  config: LiquidGlassConfig(
                    renderer: LiquidGlassRenderer.capture,
                  ),
                  width: 100,
                  height: 60,
                  child: SizedBox(),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(Alignment.topLeft, 0.5));
    await tester.pumpAndSettle();
    final initial = diagnostics!;

    await tester.pumpWidget(build(Alignment.bottomRight, 1));
    await tester.pumpAndSettle();
    final moved = diagnostics!;

    expect(moved.captureCount, greaterThan(initial.captureCount));
    expect(moved.captureRect.left, greaterThan(initial.captureRect.left));
    expect(moved.captureRect.top, greaterThan(initial.captureRect.top));
    expect(moved.pixelRatio, 1);
    expect(moved.pixelSize.width, greaterThan(initial.pixelSize.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('interactive surface handles mouse and press lifecycle',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: LiquidGlass(
            interactive: true,
            config: LiquidGlassConfig(
              renderer: LiquidGlassRenderer.fallback,
            ),
            width: 180,
            height: 96,
            child: Text('Interactive glass'),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(LiquidGlass));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(center);
    await tester.pump(const Duration(milliseconds: 90));
    await mouse.down(center);
    await tester.pump(const Duration(milliseconds: 90));
    await mouse.up();
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();

    expect(find.byType(MouseRegion), findsWidgets);
    expect(find.byType(Listener), findsWidgets);
    expect(find.text('Interactive glass'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group shares a settling motion field without stealing taps',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: LiquidGlassGroup(
            influenceRadius: 240,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LiquidGlass(
                  interactive: true,
                  config: const LiquidGlassConfig(
                    renderer: LiquidGlassRenderer.fallback,
                  ),
                  width: 120,
                  height: 64,
                  child: TextButton(
                    onPressed: () => taps += 1,
                    child: const Text('One'),
                  ),
                ),
                const SizedBox(width: 12),
                const LiquidGlass(
                  interactive: true,
                  config: LiquidGlassConfig(
                    renderer: LiquidGlassRenderer.fallback,
                  ),
                  width: 120,
                  height: 64,
                  child: Text('Two'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final first = tester.getCenter(find.text('One'));
    final second = tester.getCenter(find.text('Two'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: first);
    await mouse.moveTo(second);
    await tester.pump(const Duration(milliseconds: 80));
    await mouse.moveTo(first);
    await mouse.down(first);
    await mouse.up();
    await tester.pump(const Duration(milliseconds: 900));

    expect(taps, 1);
    expect(find.byType(LiquidGlassGroup), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture renderer loads and reports its active path',
      (tester) async {
    LiquidGlassRenderPath? activePath;
    LiquidGlassDiagnostics? captureDiagnostics;
    final renderPaths = <LiquidGlassRenderPath>[];
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScope(
          onDiagnosticsChanged: (value) => captureDiagnostics = value,
          background: const DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: <Color>[Colors.red, Colors.blue]),
            ),
          ),
          child: Center(
            child: LiquidGlass(
              config: const LiquidGlassConfig(
                renderer: LiquidGlassRenderer.capture,
              ),
              width: 180,
              height: 100,
              onRenderPathChanged: (path) {
                activePath = path;
                renderPaths.add(path);
              },
              child: const Text('Captured child'),
            ),
          ),
        ),
      ),
    );
    for (var attempt = 0;
        attempt < 20 && activePath != LiquidGlassRenderPath.capture;
        attempt += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(captureDiagnostics?.captureFailures, 0);
    expect(captureDiagnostics?.captureCount, greaterThan(0));
    expect(
      activePath,
      LiquidGlassRenderPath.capture,
      reason: 'reported paths: $renderPaths',
    );
    expect(find.text('Captured child'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Replacing the scope must transfer capture ownership without disposing an
    // image that the current raster frame can still reference.
    activePath = null;
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScope(
          background: const ColoredBox(color: Colors.green),
          child: Center(
            child: LiquidGlass(
              config: const LiquidGlassConfig(
                renderer: LiquidGlassRenderer.capture,
              ),
              width: 180,
              height: 100,
              onRenderPathChanged: (path) => activePath = path,
              child: const Text('Captured child'),
            ),
          ),
        ),
      ),
    );
    for (var attempt = 0;
        attempt < 20 && activePath != LiquidGlassRenderPath.capture;
        attempt += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(activePath, LiquidGlassRenderPath.capture);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture surface safely paints a composited foreground child',
      (tester) async {
    LiquidGlassRenderPath? activePath;
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidGlassScene(
          content: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.orange, Colors.blue],
              ),
            ),
          ),
          glass: Center(
            child: LiquidGlass(
              config: const LiquidGlassConfig(
                renderer: LiquidGlassRenderer.capture,
              ),
              width: 220,
              padding: const EdgeInsets.all(12),
              onRenderPathChanged: (path) => activePath = path,
              child: const RepaintBoundary(
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.tune_rounded),
                      Expanded(child: Slider(value: 0.6, onChanged: null)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var attempt = 0;
        attempt < 20 && activePath != LiquidGlassRenderPath.capture;
        attempt += 1) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(activePath, LiquidGlassRenderPath.capture);
    expect(tester.takeException(), isNull);
  });
}
