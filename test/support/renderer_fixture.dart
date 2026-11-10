import 'package:flutter/material.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

/// Versioned deterministic scenes shared by package and device visual checks.
enum FixtureBackdrop {
  coordinates,
  verticalStripes,
  horizontalStripes,
  checkerboard,
  split,
  text,
  gradient
}

/// Analytical reference for the moving three-stop calibration gradient.
Color fixtureGradientColorAt(Size size, double phase, Offset point) {
  final dx = size.width * (1 - 2 * phase);
  final dy = size.height;
  final t = (((point.dx - size.width * phase) * dx + point.dy * dy) /
          (dx * dx + dy * dy))
      .clamp(0.0, 1.0);
  return t <= 0.5
      ? Color.lerp(Colors.pink, Colors.indigo, t * 2)!
      : Color.lerp(Colors.indigo, Colors.cyan, (t - 0.5) * 2)!;
}

class RendererFixture extends StatelessWidget {
  const RendererFixture({
    required this.config,
    this.backdrop = FixtureBackdrop.coordinates,
    this.shape = const LiquidGlassShape.roundedRectangle(),
    this.surface = const Rect.fromLTWH(110, 80, 180, 140),
    this.showForeground = false,
    this.phase = 0,
    this.qualityScale = 1,
    this.sceneSize = const Size(400, 300),
    this.capturePixelRatio,
    this.surfaceScale = 1,
    this.surfaceRotation = 0,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.interactive = false,
    this.semanticLabel,
    this.foreground,
    this.mediaHighContrast = false,
    this.textScale = 1,
    this.fullViewBoundary = false,
    this.backgroundScrollController,
    this.additionalSurfaces = const <Rect>[],
    this.onPath,
    this.onDiagnostics,
    super.key,
  });

  static const version = 5;
  static const boundaryKey = ValueKey<String>('renderer-fixture-image');
  static const size = Size(400, 300);

  final LiquidGlassConfig config;
  final FixtureBackdrop backdrop;
  final LiquidGlassShape shape;
  final Rect surface;
  final bool showForeground;
  final double phase;
  final double qualityScale;
  final Size sceneSize;
  final double? capturePixelRatio;
  final double surfaceScale;
  final double surfaceRotation;
  final LiquidGlassAccessibilityPolicy accessibility;
  final bool interactive;
  final String? semanticLabel;
  final Widget? foreground;
  final bool mediaHighContrast;
  final double textScale;
  final bool fullViewBoundary;
  final ScrollController? backgroundScrollController;
  final List<Rect> additionalSurfaces;
  final ValueChanged<LiquidGlassRenderPath>? onPath;
  final ValueChanged<LiquidGlassDiagnostics>? onDiagnostics;

  @override
  Widget build(BuildContext context) {
    final observer = RendererFixtureObserver.maybeOf(context);
    final backdropWidget = CustomPaint(
      painter: _FixturePainter(backdrop, phase),
      child: backdrop == FixtureBackdrop.text
          ? const Center(
              child: Text('BACKGROUND 0123456789',
                  style: TextStyle(
                      inherit: false, color: Colors.black, fontSize: 14),
                  textDirection: TextDirection.ltr))
          : null,
    );
    final content = Center(
      // Keep calibration coordinates independent of a phone's logical width.
      // The main surface stays visible; offscreen source content is still part
      // of the scene captured by the fixture's own repaint boundary.
      child: OverflowBox(
        minWidth: sceneSize.width,
        maxWidth: sceneSize.width,
        minHeight: sceneSize.height,
        maxHeight: sceneSize.height,
        child: RepaintBoundary(
          key: fullViewBoundary ? null : boundaryKey,
          child: LiquidGlassScope(
            qualityScale: qualityScale,
            pixelRatio: capturePixelRatio,
            onDiagnosticsChanged: onDiagnostics,
            background: backgroundScrollController == null
                ? backdropWidget
                : SingleChildScrollView(
                    controller: backgroundScrollController,
                    child: SizedBox(
                        width: sceneSize.width,
                        height: sceneSize.height * 4,
                        child: backdropWidget)),
            child: Stack(
              children: <Widget>[
                for (final rect in additionalSurfaces)
                  Positioned.fromRect(
                    rect: rect,
                    child: LiquidGlass(
                        config: config,
                        accessibility: accessibility,
                        child: const SizedBox()),
                  ),
                Positioned.fromRect(
                  rect: surface,
                  child: _transformed(LiquidGlass(
                    config: config,
                    accessibility: accessibility,
                    interactive: interactive,
                    semanticLabel: semanticLabel,
                    shape: shape,
                    onRenderPathChanged: (path) {
                      onPath?.call(path);
                      observer?.onPath(path);
                    },
                    child: foreground ??
                        (showForeground
                            ? const Center(
                                child: RepaintBoundary(
                                  child: SizedBox(
                                    width: 80,
                                    height: 28,
                                    child: ColoredBox(
                                      color: Colors.white,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Text('Sharp',
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12)),
                                          Icon(Icons.add,
                                              color: Colors.black, size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox()),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
          highContrast: mediaHighContrast,
          textScaler: TextScaler.linear(textScale)),
      child: fullViewBoundary
          ? RepaintBoundary(key: boundaryKey, child: content)
          : content,
    );
  }

  Widget _transformed(Widget child) => surfaceScale == 1 && surfaceRotation == 0
      ? child
      : Transform.rotate(
          angle: surfaceRotation,
          child: Transform.scale(scale: surfaceScale, child: child));
}

class RendererFixtureObserver extends InheritedWidget {
  const RendererFixtureObserver(
      {required this.onPath, required super.child, super.key});
  final ValueChanged<LiquidGlassRenderPath> onPath;
  static RendererFixtureObserver? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RendererFixtureObserver>();
  @override
  bool updateShouldNotify(RendererFixtureObserver oldWidget) =>
      oldWidget.onPath != onPath;
}

/// Removes artistic lighting so pixel checks isolate coordinate displacement.
const coordinateGlassConfig = LiquidGlassConfig(
  renderer: LiquidGlassRenderer.capture,
  blurSigma: 0,
  refractionStrength: 0.12,
  thickness: 2,
  edgeWidth: 0.5,
  roughness: 0,
  transmission: 1,
  absorptionStrength: 0,
  scatteringStrength: 0,
  dispersionStrength: 0,
  chromaticAberration: 0,
  environmentStrength: 0,
  coatStrength: 0,
  causticStrength: 0,
  fresnelStrength: 0,
  specularStrength: 0,
  innerShadow: 0,
  saturation: 1,
  tint: Colors.transparent,
  noise: 0,
  quality: LiquidGlassQuality.performance,
);

class _FixturePainter extends CustomPainter {
  const _FixturePainter(this.backdrop, this.phase);
  final FixtureBackdrop backdrop;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    switch (backdrop) {
      case FixtureBackdrop.coordinates:
        // The channels encode scope coordinates, so a wrong origin, scale,
        // axis direction, or refraction sign changes directly observable pixels.
        // Two opaque axis gradients encode the same coordinates without a
        // separate draw operation for every logical pixel on older GPUs.
        paint.isAntiAlias = false;
        final bounds = Offset.zero & size;
        paint.shader = const LinearGradient(
                colors: <Color>[Color(0xFF000040), Color(0xFFFF0040)])
            .createShader(bounds);
        canvas.drawRect(bounds, paint);
        paint
          ..blendMode = BlendMode.plus
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF000000), Color(0xFF00FF00)])
              .createShader(bounds);
        canvas.drawRect(bounds, paint);
      case FixtureBackdrop.verticalStripes:
      case FixtureBackdrop.horizontalStripes:
        final vertical = backdrop == FixtureBackdrop.verticalStripes;
        canvas.drawColor(Colors.white, BlendMode.src);
        for (var p = 0.0; p < (vertical ? size.width : size.height); p += 16) {
          canvas.drawRect(
              vertical
                  ? Rect.fromLTWH(p, 0, 8, size.height)
                  : Rect.fromLTWH(0, p, size.width, 8),
              paint..color = Colors.black);
        }
      case FixtureBackdrop.checkerboard:
        for (var y = 0.0; y < size.height; y += 8) {
          for (var x = 0.0; x < size.width; x += 8) {
            paint.color =
                ((x + y) / 8).round().isEven ? Colors.white : Colors.black;
            canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), paint);
          }
        }
      case FixtureBackdrop.split:
        canvas.drawColor(Colors.white, BlendMode.src);
        canvas.drawRect(
            Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
            paint..color = Colors.black);
      case FixtureBackdrop.text:
        canvas.drawColor(const Color(0xFFE0E0E0), BlendMode.src);
        for (var y = 0.0; y < size.height; y += 12) {
          canvas.drawLine(
              Offset(0, y),
              Offset(size.width, y),
              paint
                ..color = Colors.blue
                ..strokeWidth = 1);
        }
      case FixtureBackdrop.gradient:
        paint.shader = LinearGradient(
          begin: Alignment(-1 + phase * 2, -1),
          end: Alignment(1 - phase * 2, 1),
          colors: const <Color>[Colors.pink, Colors.indigo, Colors.cyan],
        ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(_FixturePainter oldDelegate) =>
      oldDelegate.backdrop != backdrop || oldDelegate.phase != phase;
}
