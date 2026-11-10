import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';
import 'package:liquid_glass_effect_flutter/src/widgets/liquid_glass_scope.dart';

import 'renderer_fixture.dart';

/// Pixels copied from the presented view, mapped back to fixture coordinates.
class RendererContractImage {
  const RendererContractImage(
      {required this.width,
      required this.rgba,
      required this.png,
      required this.pixelRatio,
      required this.origin});
  final int width;
  final Uint8List rgba;
  final Uint8List png;
  final double pixelRatio;
  final Offset origin;
}

void registerRendererContractTests({
  Future<void> Function(String name, Uint8List png)? saveImage,
  void Function(String name, Map<String, Object?> observation)? onObservation,
  Future<RendererContractImage> Function(
          WidgetTester tester, RendererFixture fixture)?
      captureVisibleView,
}) {
  void contractTest(String name, WidgetTesterCallback callback) {
    final filter = Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
            .queryParameters['contract'] ??
        const String.fromEnvironment('RENDERER_CONTRACT_FILTER');
    if (filter.isEmpty || name.contains(filter)) {
      testWidgets(name, callback);
    }
  }

  Future<_Pixels> render(
      WidgetTester tester, RendererFixture fixture, String name) async {
    void trace(String phase) {
      if (const bool.fromEnvironment('RENDERER_TRACE_STEPS')) {
        debugPrint('FIXTURE_STEP $name $phase');
      }
    }

    trace('pump');
    LiquidGlassRenderPath? observedPath;
    final observedFixture = RendererFixtureObserver(
        onPath: (path) => observedPath = path, child: fixture);
    await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        home: captureVisibleView == null
            ? observedFixture
            : LayoutBuilder(builder: (context, constraints) {
                // Preserve the fixture's logical scale, including the
                // untransformed window-target filter contract. Its probes fit
                // a 360px phone even when the source plane overflows slightly.
                // Snap the centered scene to the physical pixel grid so x/y
                // stripe probes share the same rasterization phase in either
                // phone orientation. No optical tolerance is changed.
                final ratio = tester.view.devicePixelRatio;
                final origin = Offset(
                    (constraints.maxWidth - fixture.sceneSize.width) / 2,
                    (constraints.maxHeight - fixture.sceneSize.height) / 2);
                final aligned = Offset((origin.dx * ratio).round() / ratio,
                    (origin.dy * ratio).round() / ratio);
                return Transform.translate(
                    offset: aligned - origin, child: observedFixture);
              })));
    await tester.pumpAndSettle();
    if (captureVisibleView != null) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    trace('settled');
    final opaque = fixture.accessibility.reduceTransparency ||
        (fixture.accessibility.highContrast ?? fixture.mediaHighContrast);
    final expectedPath = opaque
        ? LiquidGlassRenderPath.fallback
        : switch (fixture.config.renderer) {
            LiquidGlassRenderer.auto ||
            LiquidGlassRenderer.capture =>
              LiquidGlassRenderPath.capture,
            LiquidGlassRenderer.shader =>
              LiquidGlassCapabilities.supportsShaderBackdropFilter
                  ? LiquidGlassRenderPath.filter
                  : LiquidGlassRenderPath.fallback,
            LiquidGlassRenderer.fallback => LiquidGlassRenderPath.fallback,
          };
    expect(observedPath, expectedPath,
        reason: 'Fixture $name must exercise its intended concrete renderer');
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(RendererFixture.boundaryKey));
    final result = await tester.runAsync(() async {
      trace('readback');
      if (captureVisibleView != null) {
        final capture = await captureVisibleView(tester, fixture);
        await saveImage?.call(name, capture.png);
        return _Pixels(capture.width, capture.rgba,
            ratio: capture.pixelRatio, origin: capture.origin);
      }
      final ratio =
          fixture.fullViewBoundary ? tester.view.devicePixelRatio : 1.0;
      final image = await boundary
          .toImage(pixelRatio: ratio)
          .timeout(const Duration(seconds: 15));
      trace('image-ready');
      try {
        final data = await image
            .toByteData(format: ui.ImageByteFormat.rawRgba)
            .timeout(const Duration(seconds: 15));
        trace('rgba-ready');
        final png = await image
            .toByteData(format: ui.ImageByteFormat.png)
            .timeout(const Duration(seconds: 15));
        trace('png-ready');
        await saveImage?.call(name, png!.buffer.asUint8List());
        return _Pixels(image.width, data!.buffer.asUint8List(),
            ratio: ratio,
            origin: fixture.fullViewBoundary
                ? Offset(
                    (tester.view.physicalSize.width / ratio -
                            fixture.sceneSize.width) /
                        2,
                    (tester.view.physicalSize.height / ratio -
                            fixture.sceneSize.height) /
                        2)
                : Offset.zero);
      } finally {
        image.dispose();
      }
    });
    trace('readback-complete');
    if (onObservation != null) {
      final handle =
          liquidGlassCaptureOf(tester.element(find.byType(LiquidGlass).first))!;
      final data = handle.diagnostics;
      final sourceImage = handle.image;
      if (captureVisibleView == null &&
          sourceImage != null &&
          saveImage != null) {
        trace('source-readback');
        await tester.runAsync(() async {
          final png = await sourceImage
              .toByteData(format: ui.ImageByteFormat.png)
              .timeout(const Duration(seconds: 15));
          await saveImage('$name-source-capture', png!.buffer.asUint8List());
        });
        trace('source-readback-complete');
      }
      onObservation(name, <String, Object?>{
        'requestedRenderer': fixture.config.renderer.name,
        'readbackPixelRatio': result!.ratio,
        'readbackOrigin': <double>[result.origin.dx, result.origin.dy],
        'activePath': observedPath?.name,
        'surfaceScale': fixture.surfaceScale,
        'surfaceRotationRadians': fixture.surfaceRotation,
        'textScale': fixture.textScale,
        'highContrast': fixture.mediaHighContrast,
        'generation': data.generation,
        'captureCount': data.captureCount,
        'captureFailures': data.captureFailures,
        'activeSurfaceCount': data.activeSurfaceCount,
        'captureSupported': data.captureSupported,
        'scopeSize': <double>[data.scopeSize.width, data.scopeSize.height],
        'captureRect': <double>[
          data.captureRect.left,
          data.captureRect.top,
          data.captureRect.width,
          data.captureRect.height
        ],
        'pixelSize': <double>[data.pixelSize.width, data.pixelSize.height],
        'capturePixelRatio': data.pixelRatio,
        'captureAreaRatio': data.captureAreaRatio,
        'currentBytes': data.estimatedBytes,
        'retainedBytes': data.retainedBytes,
        'peakRetainedBytes': data.peakRetainedBytes,
        'retiredImageCount': data.retiredImageCount,
      });
    }
    trace('complete');
    return result!;
  }

  contractTest(
      'convex capture samples toward its center and preserves the flat interior',
      (tester) async {
    LiquidGlassRenderPath? path;
    final reference = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.fallback)),
        'coordinates-reference');
    final captured = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig, onPath: (value) => path = value),
        'coordinates-capture');
    expect(path, LiquidGlassRenderPath.capture);
    expect(captured.channel(115, 150, 0),
        greaterThan(reference.channel(115, 150, 0) + 2));
    expect(captured.channel(284, 150, 0),
        lessThan(reference.channel(284, 150, 0) - 2));
    expect(captured.channel(200, 85, 1),
        greaterThan(reference.channel(200, 85, 1) + 2));
    expect(captured.channel(200, 214, 1),
        lessThan(reference.channel(200, 214, 1) - 2));
    final leftTravel =
        (captured.channel(115, 150, 0) - reference.channel(115, 150, 0)) *
            400 /
            255;
    final rightTravel =
        (reference.channel(284, 150, 0) - captured.channel(284, 150, 0)) *
            400 /
            255;
    final topTravel =
        (captured.channel(200, 85, 1) - reference.channel(200, 85, 1)) *
            300 /
            255;
    expect(leftTravel, closeTo(rightTravel, 3));
    expect(leftTravel, closeTo(topTravel, 3));
    for (var channel = 0; channel < 3; channel += 1) {
      expect(captured.channel(200, 150, channel),
          closeTo(reference.channel(200, 150, channel), 2));
      expect(captured.channel(40, 40, channel),
          reference.channel(40, 40, channel));
    }
  });

  contractTest('calibration stripes preserve axis symmetry and a stable center',
      (tester) async {
    const square = Rect.fromLTWH(112, 80, 144, 144);
    final profiles = <_Pixels>[];
    final references = <_Pixels>[];
    for (final backdrop in <FixtureBackdrop>[
      FixtureBackdrop.verticalStripes,
      FixtureBackdrop.horizontalStripes
    ]) {
      references.add(await render(
          tester,
          RendererFixture(
              config: coordinateGlassConfig.copyWith(
                  renderer: LiquidGlassRenderer.fallback),
              backdrop: backdrop,
              surface: square),
          'stripes-${backdrop.name}-reference'));
      profiles.add(await render(
          tester,
          RendererFixture(
              config: coordinateGlassConfig,
              backdrop: backdrop,
              surface: square),
          'stripes-${backdrop.name}-capture'));
    }
    var displaced = 0;
    for (var inset = 3; inset < 35; inset += 1) {
      final x = profiles[0].channel(112 + inset, 152, 0);
      final y = profiles[1].channel(184, 80 + inset, 0);
      expect(x, closeTo(y, 2));
      if ((x - references[0].channel(112 + inset, 152, 0)).abs() > 16) {
        displaced += 1;
      }
    }
    expect(displaced, greaterThan(8));
    for (var axis = 0; axis < 2; axis += 1) {
      expect(profiles[axis].pixel(184, 152), references[axis].pixel(184, 152));
    }
  });

  contractTest(
      'calibration material preserves light and dark backdrop hierarchy',
      (tester) async {
    final pixels = await render(
        tester,
        RendererFixture(
            config: const LiquidGlassConfig.regular()
                .copyWith(renderer: LiquidGlassRenderer.capture),
            backdrop: FixtureBackdrop.split),
        'split-regular');
    final light = <int>[for (var c = 0; c < 3; c++) pixels.channel(135, 150, c)]
            .reduce((a, b) => a + b) /
        3;
    final dark = <int>[for (var c = 0; c < 3; c++) pixels.channel(265, 150, c)]
            .reduce((a, b) => a + b) /
        3;
    expect(light, greaterThan(dark + 100));
    expect(pixels.channel(135, 150, 3), 255);
    expect(pixels.channel(265, 150, 3), 255);
    expect(pixels.pixel(40, 150), <int>[255, 255, 255, 255]);
    expect(pixels.pixel(350, 150), <int>[0, 0, 0, 255]);
  });

  contractTest(
      'calibration background text and vectors blur below sharp content',
      (tester) async {
    final reference = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.fallback),
            backdrop: FixtureBackdrop.text,
            showForeground: true),
        'text-lines-reference');
    final blurred = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                refractionStrength: 0,
                blurSigma: 12,
                roughness: 0.45,
                quality: LiquidGlassQuality.ultra),
            backdrop: FixtureBackdrop.text,
            showForeground: true),
        'text-lines-blurred');
    double edgeEnergy(_Pixels pixels) {
      var sum = 0.0;
      for (var y = 100; y < 128; y++) {
        for (var x = 130; x < 150; x++) {
          sum += (pixels.channel(x, y + 1, 0) - pixels.channel(x, y, 0)).abs();
        }
      }
      return sum;
    }

    final sharpEdges = edgeEnergy(reference);
    expect(sharpEdges, greaterThan(1000));
    // The material uses a normalized sparse stencil, not a Gaussian filter.
    // It must reduce edge contrast while preserving the separate foreground.
    expect(edgeEnergy(blurred), lessThan(sharpEdges));
    for (var y = 138; y < 162; y++) {
      for (var x = 162; x < 238; x++) {
        expect(blurred.pixel(x, y), reference.pixel(x, y));
      }
    }
  });

  contractTest('calibration real scrolling refreshes the retained glass image',
      (tester) async {
    final controller = ScrollController();
    LiquidGlassDiagnostics? diagnostics;
    final fixture = RendererFixture(
        config: coordinateGlassConfig.copyWith(refractionStrength: 0),
        backdrop: FixtureBackdrop.horizontalStripes,
        backgroundScrollController: controller,
        onDiagnostics: (value) => diagnostics = value);
    try {
      final before = await render(tester, fixture, 'scroll-before');
      final count = diagnostics!.captureCount;
      controller.jumpTo(20);
      await tester.pumpAndSettle();
      final after = await render(tester, fixture, 'scroll-after');
      expect(diagnostics!.captureCount, greaterThan(count));
      expect(before.channel(200, 150, 0), lessThan(8));
      expect(after.channel(200, 150, 0), greaterThan(247));
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    }
  });

  contractTest('all surface silhouettes clip the optical pass', (tester) async {
    final reference = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.fallback)),
        'clipping-reference');
    for (final shape in <LiquidGlassShape>[
      const LiquidGlassShape.roundedRectangle(),
      const LiquidGlassShape.capsule(),
      const LiquidGlassShape.circle()
    ]) {
      final pixels = await render(
          tester,
          RendererFixture(config: coordinateGlassConfig, shape: shape),
          'clipping-${shape.kind.name}');
      for (final point in <Offset>[
        const Offset(111, 81),
        const Offset(109, 150),
        const Offset(290, 150),
        const Offset(200, 79),
        const Offset(200, 220)
      ]) {
        expect(pixels.pixel(point.dx.toInt(), point.dy.toInt()),
            reference.pixel(point.dx.toInt(), point.dy.toInt()),
            reason: 'Optics escaped ${shape.kind.name}');
      }
      expect(pixels.channel(115, 150, 0),
          greaterThan(reference.channel(115, 150, 0) + 2));
    }
  });

  contractTest(
      'scope resize and DPR changes refresh sampling without scaling content',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;
    final config = coordinateGlassConfig.copyWith(refractionStrength: 0);
    await render(
        tester,
        RendererFixture(
            config: config,
            capturePixelRatio: 1,
            onDiagnostics: (value) => diagnostics = value),
        'resize-before');
    final generation = diagnostics!.generation;
    final resized = await render(
        tester,
        RendererFixture(
            config: config,
            sceneSize: const Size(380, 280),
            capturePixelRatio: 2.625,
            qualityScale: 0.65,
            onDiagnostics: (value) => diagnostics = value),
        'resize-dpr-after');
    expect(diagnostics!.generation, greaterThan(generation));
    expect(diagnostics!.scopeSize, const Size(380, 280));
    expect(diagnostics!.pixelRatio, closeTo(2.625 * 0.65, 0.000001));
    expect(resized.channel(200, 150, 0), closeTo(200 / 380 * 255, 2));
    expect(resized.channel(200, 150, 1), closeTo(150 / 280 * 255, 2));
  });

  contractTest('movement inside a shared crop does not recapture content',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;
    final config = coordinateGlassConfig.copyWith(refractionStrength: 0);
    const distant = <Rect>[
      Rect.fromLTWH(10, 10, 50, 50),
      Rect.fromLTWH(340, 240, 50, 50)
    ];
    await render(
        tester,
        RendererFixture(
            config: config,
            surface: const Rect.fromLTWH(100, 90, 100, 70),
            additionalSurfaces: distant,
            onDiagnostics: (value) => diagnostics = value),
        'shared-crop-before');
    final count = diagnostics!.captureCount;
    final moved = await render(
        tester,
        RendererFixture(
            config: config,
            surface: const Rect.fromLTWH(200, 110, 100, 70),
            additionalSurfaces: distant,
            onDiagnostics: (value) => diagnostics = value),
        'shared-crop-moved');
    expect(diagnostics!.captureCount, count);
    expect(diagnostics!.activeSurfaceCount, 3);
    expect(moved.channel(250, 145, 0), closeTo(250 / 400 * 255, 2));
    expect(moved.channel(35, 35, 0), closeTo(35 / 400 * 255, 2));
    expect(moved.channel(365, 265, 1), closeTo(265 / 300 * 255, 2));
  });

  contractTest('composited foreground text and icon remain pixel sharp',
      (tester) async {
    LiquidGlassRenderPath? path;
    final reference = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.fallback),
            showForeground: true,
            backdrop: FixtureBackdrop.checkerboard),
        'foreground-reference');
    final captured = await render(
        tester,
        RendererFixture(
            config: const LiquidGlassConfig.frosted()
                .copyWith(renderer: LiquidGlassRenderer.capture),
            onPath: (value) => path = value,
            showForeground: true,
            backdrop: FixtureBackdrop.checkerboard),
        'foreground-capture');
    expect(path, LiquidGlassRenderPath.capture);
    for (var y = 137; y < 163; y += 1) {
      for (var x = 161; x < 239; x += 1) {
        expect(captured.pixel(x, y), reference.pixel(x, y),
            reason: 'Foreground differs at ($x, $y)');
      }
    }
  });

  contractTest('scaled and rotated surfaces preserve scope coordinate mapping',
      (tester) async {
    final config = coordinateGlassConfig.copyWith(refractionStrength: 0);
    for (final transform in <(double, double)>[
      (1.4, 0),
      (1, 0.35),
      (0.8, -0.5)
    ]) {
      final pixels = await render(
          tester,
          RendererFixture(
              config: config,
              surfaceScale: transform.$1,
              surfaceRotation: transform.$2),
          'affine-${transform.$1}-${transform.$2}');
      for (final point in <Offset>[
        const Offset(200, 150),
        const Offset(180, 135),
        const Offset(220, 165)
      ]) {
        expect(pixels.channel(point.dx.toInt(), point.dy.toInt(), 0),
            closeTo(point.dx / 400 * 255, 2));
        expect(pixels.channel(point.dx.toInt(), point.dy.toInt(), 1),
            closeTo(point.dy / 300 * 255, 2));
      }
    }
  });

  contractTest('crop origin and fractional capture scale preserve coordinates',
      (tester) async {
    final config = coordinateGlassConfig.copyWith(refractionStrength: 0);
    for (final scale in <double>[0.65, 1]) {
      final pixels = await render(
          tester,
          RendererFixture(
              config: config,
              qualityScale: scale,
              surface: const Rect.fromLTWH(213.25, 37.75, 103.5, 137.25)),
          'crop-$scale');
      for (final point in <Offset>[
        const Offset(235, 65),
        const Offset(260, 100),
        const Offset(290, 140)
      ]) {
        expect(pixels.channel(point.dx.toInt(), point.dy.toInt(), 0),
            closeTo(point.dx / 400 * 255, 2));
        expect(pixels.channel(point.dx.toInt(), point.dy.toInt(), 1),
            closeTo(point.dy / 300 * 255, 2));
      }
    }
  });

  contractTest(
      'anisotropic scattering is independent of the capture aspect ratio',
      (tester) async {
    final config = coordinateGlassConfig.copyWith(
        refractionStrength: 0,
        blurSigma: 12,
        roughness: 0.45,
        quality: LiquidGlassQuality.ultra,
        anisotropy: 0.95,
        anisotropyRotation: 0.125);
    for (final captureRatio in <double?>[null, 2.625]) {
      final cropped = await render(
          tester,
          RendererFixture(
              config: config,
              backdrop: FixtureBackdrop.checkerboard,
              capturePixelRatio: captureRatio),
          'anisotropic-crop-${captureRatio ?? 'device'}');
      final full = await render(
          tester,
          RendererFixture(
              config: config,
              capturePixelRatio: captureRatio,
              backdrop: FixtureBackdrop.checkerboard,
              additionalSurfaces: const <Rect>[
                Rect.fromLTWH(0, 0, 1, 1),
                Rect.fromLTWH(399, 299, 1, 1)
              ]),
          'anisotropic-full-scope-${captureRatio ?? 'device'}');
      for (var y = 90; y < 210; y += 9) {
        for (var x = 120; x < 280; x += 9) {
          for (var c = 0; c < 4; c += 1) {
            expect(cropped.channel(x, y, c), closeTo(full.channel(x, y, c), 2),
                reason:
                    'Capture aspect changes ($x, $y) channel $c ratio=$captureRatio');
          }
        }
      }
    }
  });

  contractTest('retained glass samples the updated content generation',
      (tester) async {
    LiquidGlassDiagnostics? diagnostics;
    final config = coordinateGlassConfig.copyWith(refractionStrength: 0);
    final before = await render(
        tester,
        RendererFixture(
            config: config,
            backdrop: FixtureBackdrop.gradient,
            phase: 0,
            onDiagnostics: (value) => diagnostics = value),
        'live-before');
    final initialCount = diagnostics!.captureCount;
    final after = await render(
        tester,
        RendererFixture(
            config: config,
            backdrop: FixtureBackdrop.gradient,
            phase: 1,
            onDiagnostics: (value) => diagnostics = value),
        'live-after');
    expect(diagnostics!.captureCount, greaterThan(initialCount));
    expect(after.pixel(170, 130), isNot(before.pixel(170, 130)));
    final reference = await render(
        tester,
        RendererFixture(
            config: config.copyWith(renderer: LiquidGlassRenderer.fallback),
            backdrop: FixtureBackdrop.gradient,
            phase: 1),
        'live-reference');
    for (var channel = 0; channel < 4; channel += 1) {
      expect(after.channel(170, 130, channel),
          closeTo(reference.channel(170, 130, channel), 2));
    }
  });

  contractTest('capture failure releases the image and reports fallback once',
      (tester) async {
    LiquidGlassRenderPath? path;
    LiquidGlassDiagnostics? diagnostics;
    await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig,
            onPath: (value) => path = value,
            onDiagnostics: (value) => diagnostics = value),
        'failure-before');
    expect(path, LiquidGlassRenderPath.capture);
    final handle =
        liquidGlassCaptureOf(tester.element(find.byType(LiquidGlass)))!;
    handle.markUnsupported(
        StateError('Injected capture failure'), StackTrace.current);
    handle.markUnsupported(StateError('Repeated failure'), StackTrace.current);
    await tester.pumpAndSettle();
    expect(path, LiquidGlassRenderPath.fallback);
    expect(diagnostics!.captureSupported, isFalse);
    expect(diagnostics!.captureFailures, 1);
    expect(diagnostics!.estimatedBytes, 0);
    expect(tester.takeException(), isNull);
  });

  contractTest(
      'transparency and contrast policies render opaque without advanced sampling',
      (tester) async {
    const color = Color(0xFF223344);
    final reduced = await render(
        tester,
        const RendererFixture(
            config: coordinateGlassConfig,
            accessibility: LiquidGlassAccessibilityPolicy(
                reduceTransparency: true, opaqueColor: color)),
        'a11y-reduced-transparency');
    expect(reduced.pixel(200, 150), <int>[34, 51, 68, 255]);
    final contrast = await render(
        tester,
        const RendererFixture(
            config: coordinateGlassConfig,
            mediaHighContrast: true,
            textScale: 2,
            accessibility: LiquidGlassAccessibilityPolicy(opaqueColor: color),
            foreground: Center(
                child: Text('Readable', style: TextStyle(fontSize: 16)))),
        'a11y-high-contrast-large-text');
    expect(contrast.pixel(200, 90), <int>[34, 51, 68, 255]);
    expect(find.byType(BackdropFilter), findsNothing);
    final override = await render(
        tester,
        const RendererFixture(
            config: coordinateGlassConfig,
            mediaHighContrast: true,
            accessibility: LiquidGlassAccessibilityPolicy(highContrast: false)),
        'a11y-contrast-override');
    expect(override.channel(200, 150, 0), closeTo(127.5, 2));
  });

  contractTest('reduced motion leaves the captured material idle',
      (tester) async {
    await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(animateLight: true),
            accessibility:
                const LiquidGlassAccessibilityPolicy(reduceMotion: true),
            interactive: true),
        'a11y-reduced-motion');
    expect(tester.binding.transientCallbackCount, 0);
  });

  contractTest('explicit filter bends the backdrop and keeps foreground sharp',
      (tester) async {
    final reference = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.fallback),
            showForeground: true,
            fullViewBoundary: true),
        'filter-reference');
    final filtered = await render(
        tester,
        RendererFixture(
            config: coordinateGlassConfig.copyWith(
                renderer: LiquidGlassRenderer.shader),
            showForeground: true,
            fullViewBoundary: true),
        'filter-explicit');
    if (LiquidGlassCapabilities.supportsShaderBackdropFilter) {
      expect(filtered.channel(115, 150, 0),
          greaterThan(reference.channel(115, 150, 0) + 2));
      expect(filtered.channel(284, 150, 0),
          lessThan(reference.channel(284, 150, 0) - 2));
      expect(filtered.channel(200, 85, 1),
          greaterThan(reference.channel(200, 85, 1) + 2));
      expect(filtered.channel(200, 214, 1),
          lessThan(reference.channel(200, 214, 1) - 2));
    }
    for (var y = 138; y < 162; y += 1) {
      for (var x = 162; x < 238; x += 1) {
        expect(filtered.pixel(x, y), reference.pixel(x, y));
      }
    }
  });

  contractTest(
      'keyboard and accessibility focus remain visible without consuming child actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final focus = FocusNode();
    var activations = 0;
    final fixture = RendererFixture(
        config: coordinateGlassConfig,
        interactive: true,
        semanticLabel: 'Tools',
        foreground: Center(
            child: TextButton(
                focusNode: focus,
                onPressed: () => activations += 1,
                child: const Text('Activate'))));
    try {
      final before = await render(tester, fixture, 'a11y-focus-before');
      focus.requestFocus();
      await tester.pumpAndSettle();
      final focused = await render(tester, fixture, 'a11y-keyboard-focus');
      expect(focused.pixel(113, 150), isNot(before.pixel(113, 150)));
      expect(focused.pixel(113, 150), <int>[255, 255, 255, 255]);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter,
          physicalKey: PhysicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activations, 1);
      focus.unfocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      // getSemantics relies on RenderObject.debugSemantics, which is absent
      // from release web builds. Walk the public semantics tree instead.
      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      SemanticsNode? node;
      void visit(SemanticsNode current) {
        if (current.getSemanticsData().label == 'Tools') node = current;
        current.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      visit(owner.rootSemanticsNode!);
      expect(node, isNotNull);
      owner.performAction(
          node!.id, ui.SemanticsAction.didGainAccessibilityFocus);
      await tester.pumpAndSettle();
      final accessible =
          await render(tester, fixture, 'a11y-accessibility-focus');
      expect(accessible.pixel(113, 150), <int>[255, 255, 255, 255]);
    } finally {
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      semantics.dispose();
    }
  });
}

class _Pixels {
  const _Pixels(this.width, this.bytes,
      {this.ratio = 1, this.origin = Offset.zero});
  final int width;
  final Uint8List bytes;
  final double ratio;
  final Offset origin;
  // Match the center of logical pixel (x, y), as a 1x boundary image does.
  // Sampling its edge can land inside a clip or on the other side of a stripe
  // when the presented view has a fractional device-pixel ratio.
  int channel(int x, int y, int channel) =>
      bytes[(((origin.dy + y + 0.5) * ratio).floor() * width +
                  ((origin.dx + x + 0.5) * ratio).floor()) *
              4 +
          channel];
  List<int> pixel(int x, int y) =>
      List<int>.generate(4, (c) => channel(x, y, c));
}
