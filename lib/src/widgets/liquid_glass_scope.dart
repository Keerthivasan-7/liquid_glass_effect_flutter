import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' as meta;

/// Immutable telemetry for one [LiquidGlassScope].
@immutable
class LiquidGlassDiagnostics {
  const LiquidGlassDiagnostics({
    required this.generation,
    required this.captureCount,
    required this.captureFailures,
    required this.activeSurfaceCount,
    required this.captureRect,
    required this.pixelSize,
    required this.estimatedBytes,
    required this.pixelRatio,
    required this.captureSupported,
    required this.lastCaptureTime,
    this.retiredImageCount = 0,
    this.retainedBytes = 0,
    this.peakRetainedBytes = 0,
    this.scopeSize = Size.zero,
  });

  final int generation;
  final int captureCount;
  final int captureFailures;
  final int activeSurfaceCount;
  final Rect captureRect;
  final Size pixelSize;

  /// Estimated storage for the current RGBA capture, excluding retired images.
  final int estimatedBytes;

  /// Images awaiting the two-frame retirement guard.
  final int retiredImageCount;

  /// Estimated current and retired RGBA storage tracked by this scope.
  final int retainedBytes;
  final int peakRetainedBytes;
  final Size scopeSize;

  double get captureAreaRatio => scopeSize.isEmpty
      ? 0
      : captureRect.width *
          captureRect.height /
          (scopeSize.width * scopeSize.height);

  final double pixelRatio;
  final bool captureSupported;

  /// Scheduler timestamp of the most recent successful capture.
  final Duration lastCaptureTime;
}

/// Owns the captured background used by portable liquid-glass shaders.
///
/// [background] is captured without [child], preventing glass surfaces from
/// recursively sampling themselves. The scope should normally receive bounded
/// constraints (for example as the body of a [Stack]).
class LiquidGlassScope extends StatefulWidget {
  const LiquidGlassScope({
    required this.background,
    required this.child,
    this.pixelRatio,
    this.qualityScale = 0.65,
    this.onDiagnosticsChanged,
    super.key,
  })  : assert(pixelRatio == null || pixelRatio > 0),
        assert(qualityScale > 0 && qualityScale <= 1);

  final Widget background;
  final Widget child;
  final double? pixelRatio;
  final double qualityScale;

  /// Called after a frame when capture telemetry changes.
  final ValueChanged<LiquidGlassDiagnostics>? onDiagnosticsChanged;

  @override
  State<LiquidGlassScope> createState() => _LiquidGlassScopeState();
}

class _LiquidGlassScopeState extends State<LiquidGlassScope> {
  late final LiquidGlassCaptureHandle _handle;

  @override
  void initState() {
    super.initState();
    _handle = LiquidGlassCaptureHandle(
      onDiagnosticsChanged: widget.onDiagnosticsChanged,
    );
    _handle._scheduleDiagnostics();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handle.onDiagnosticsChanged = widget.onDiagnosticsChanged;
  }

  @override
  Widget build(BuildContext context) => _LiquidGlassScopeRenderWidget(
        handle: _handle,
        pixelRatio: widget.pixelRatio,
        qualityScale: widget.qualityScale,
        children: <Widget>[
          widget.background,
          RepaintBoundary(
            child: _LiquidGlassScopeInherited(
              handle: _handle,
              child: widget.child,
            ),
          ),
        ],
      );

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }
}

class _LiquidGlassScopeRenderWidget extends MultiChildRenderObjectWidget {
  const _LiquidGlassScopeRenderWidget({
    required this.handle,
    required this.pixelRatio,
    required this.qualityScale,
    required super.children,
  });

  final LiquidGlassCaptureHandle handle;
  final double? pixelRatio;
  final double qualityScale;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final devicePixelRatio =
        pixelRatio ?? MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return _RenderLiquidGlassScope(
      handle: handle,
      capturePixelRatio: devicePixelRatio * qualityScale,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    final devicePixelRatio =
        pixelRatio ?? MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    (renderObject as _RenderLiquidGlassScope)
      ..handle = handle
      ..capturePixelRatio = devicePixelRatio * qualityScale;
  }
}

/// Shared capture state read by liquid-glass render objects during paint.
@meta.internal
class LiquidGlassCaptureHandle extends ChangeNotifier {
  LiquidGlassCaptureHandle({
    ValueChanged<LiquidGlassDiagnostics>? onDiagnosticsChanged,
  }) : _onDiagnosticsChanged = onDiagnosticsChanged;

  ui.Image? _image;
  _RenderLiquidGlassScope? _scope;
  final Set<LiquidGlassCaptureClient> _clients = <LiquidGlassCaptureClient>{};
  final List<ui.Image> _retired = <ui.Image>[];
  final List<ui.Image> _retiring = <ui.Image>[];
  bool _retirementScheduled = false;
  bool _captureRequestScheduled = false;
  bool _diagnosticsScheduled = false;
  bool _captureSupported = true;
  bool _isDisposed = false;
  int _captureClients = 0;
  int _generation = 0;
  int _captureCount = 0;
  int _captureFailures = 0;
  int _peakRetainedBytes = 0;
  double _pixelRatio = 1;
  Rect _captureRect = Rect.zero;
  Duration _lastCaptureTime = Duration.zero;
  ValueChanged<LiquidGlassDiagnostics>? _onDiagnosticsChanged;

  ui.Image? get image => _image;
  RenderBox? get scopeRenderBox => _scope;
  bool get captureSupported => _captureSupported;
  double get pixelRatio => _pixelRatio;
  double get requestedPixelRatio => _scope?.capturePixelRatio ?? _pixelRatio;
  Rect get captureRect => _captureRect;

  set onDiagnosticsChanged(
    ValueChanged<LiquidGlassDiagnostics>? callback,
  ) {
    _onDiagnosticsChanged = callback;
    _scheduleDiagnostics();
  }

  void retainCapture() {
    _captureClients += 1;
    requestCapture();
  }

  void releaseCapture() {
    assert(_captureClients > 0);
    if (_captureClients > 0) {
      _captureClients -= 1;
      if (_captureClients == 0) _clearImage();
    }
  }

  void registerClient(LiquidGlassCaptureClient client) {
    if (_clients.add(client)) {
      requestCapture();
      _scheduleDiagnostics();
    }
  }

  void unregisterClient(LiquidGlassCaptureClient client) {
    if (_clients.remove(client)) {
      requestCapture();
      _scheduleDiagnostics();
    }
  }

  void requestCapture() {
    if (_isDisposed || _captureRequestScheduled) return;
    _captureRequestScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _captureRequestScheduled = false;
      if (!_isDisposed) _scope?.markNeedsPaint();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void replaceImage(ui.Image image, double pixelRatio, Rect captureRect) {
    final previous = _image;
    _image = image;
    _pixelRatio = pixelRatio;
    _captureRect = captureRect;
    _lastCaptureTime = SchedulerBinding.instance.currentFrameTimeStamp;
    _generation += 1;
    _captureCount += 1;
    if (previous != null) _retired.add(previous);
    final retained = _retainedBytes;
    if (retained > _peakRetainedBytes) _peakRetainedBytes = retained;
    _scheduleRetirement();
    _scheduleDiagnostics();
  }

  void _clearImage() {
    final previous = _image;
    if (previous == null) return;
    _image = null;
    _captureRect = Rect.zero;
    _pixelRatio = 1;
    _generation += 1;
    _retired.add(previous);
    _scheduleRetirement();
    _scheduleDiagnostics();
  }

  void markUnsupported(Object error, StackTrace stackTrace) {
    if (!_captureSupported) return;
    _captureSupported = false;
    _captureFailures += 1;
    _clearImage();
    assert(() {
      debugPrint('LiquidGlass capture unavailable; using fallback: $error');
      debugPrintStack(stackTrace: stackTrace);
      return true;
    }());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
        _scheduleDiagnostics();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  int get _retainedBytes =>
      (_image == null ? 0 : _image!.width * _image!.height * 4) +
      <ui.Image>[..._retired, ..._retiring].fold<int>(
        0,
        (total, image) => total + image.width * image.height * 4,
      );

  LiquidGlassDiagnostics get diagnostics {
    final image = _image;
    final pixelSize = image == null
        ? Size.zero
        : Size(image.width.toDouble(), image.height.toDouble());
    return LiquidGlassDiagnostics(
      generation: _generation,
      captureCount: _captureCount,
      captureFailures: _captureFailures,
      activeSurfaceCount: _clients.length,
      captureRect: _captureRect,
      pixelSize: pixelSize,
      estimatedBytes: image == null ? 0 : image.width * image.height * 4,
      pixelRatio: _pixelRatio,
      captureSupported: _captureSupported,
      lastCaptureTime: _lastCaptureTime,
      retiredImageCount: _retired.length + _retiring.length,
      retainedBytes: _retainedBytes,
      peakRetainedBytes: _peakRetainedBytes,
      scopeSize: _scope?.hasSize == true ? _scope!.size : Size.zero,
    );
  }

  void _scheduleDiagnostics() {
    if (_isDisposed || _diagnosticsScheduled || _onDiagnosticsChanged == null) {
      return;
    }
    _diagnosticsScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _diagnosticsScheduled = false;
      final callback = _onDiagnosticsChanged;
      if (!_isDisposed && callback != null) callback(diagnostics);
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _scheduleRetirement() {
    if (_retirementScheduled || _retired.isEmpty) return;
    _retirementScheduled = true;
    // Freeze this batch now. Images retired during the next frame must receive
    // their own full guard rather than being swept into an older batch.
    _retiring.addAll(_retired);
    _retired.clear();
    // Keep retired images alive for two complete frames. Canvas commands can
    // be consumed by the raster thread after the UI frame has ended.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _retirementScheduled = false;
        final images = List<ui.Image>.of(_retiring);
        _retiring.clear();
        for (final image in images) {
          image.dispose();
        }
        _scheduleRetirement();
        _scheduleDiagnostics();
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _image?.dispose();
    for (final image in _retired) {
      image.dispose();
    }
    for (final image in _retiring) {
      image.dispose();
    }
    _retired.clear();
    _retiring.clear();
    _clients.clear();
    _image = null;
    _scope = null;
    _onDiagnosticsChanged = null;
    super.dispose();
  }
}

/// A capture surface that can report its padded sample bounds to the scope.
@meta.internal
abstract interface class LiquidGlassCaptureClient {
  Rect captureBoundsIn(RenderBox scope);
}

class _LiquidGlassScopeInherited extends InheritedWidget {
  const _LiquidGlassScopeInherited({
    required this.handle,
    required super.child,
  });

  final LiquidGlassCaptureHandle handle;

  static LiquidGlassCaptureHandle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_LiquidGlassScopeInherited>()
      ?.handle;

  @override
  bool updateShouldNotify(_LiquidGlassScopeInherited oldWidget) =>
      oldWidget.handle != handle;
}

/// Internal scope lookup used by [LiquidGlass].
@meta.internal
LiquidGlassCaptureHandle? liquidGlassCaptureOf(BuildContext context) =>
    _LiquidGlassScopeInherited.maybeOf(context);

class _RenderLiquidGlassScope extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox,
            ContainerBoxParentData<RenderBox>>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ContainerBoxParentData<RenderBox>> {
  _RenderLiquidGlassScope({
    required LiquidGlassCaptureHandle handle,
    required double capturePixelRatio,
  })  : _handle = handle,
        _capturePixelRatio = capturePixelRatio {
    _handle._scope = this;
  }

  LiquidGlassCaptureHandle _handle;
  double _capturePixelRatio;

  double get capturePixelRatio => _capturePixelRatio;

  set handle(LiquidGlassCaptureHandle value) {
    if (_handle == value) return;
    final previous = _handle;
    previous._scope = null;
    _handle = value;
    _handle._scope = this;
    markNeedsPaint();
  }

  set capturePixelRatio(double value) {
    if (_capturePixelRatio == value) return;
    _capturePixelRatio = value;
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LiquidGlassScopeParentData) {
      child.parentData = _LiquidGlassScopeParentData();
    }
  }

  @override
  void performLayout() {
    if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
      size = constraints.biggest;
    } else {
      var desired = Size.zero;
      RenderBox? child = firstChild;
      while (child != null) {
        child.layout(constraints.loosen(), parentUsesSize: true);
        desired = Size(
          desired.width > child.size.width ? desired.width : child.size.width,
          desired.height > child.size.height
              ? desired.height
              : child.size.height,
        );
        child = childAfter(child);
      }
      size = constraints.constrain(desired);
    }

    final childConstraints = BoxConstraints.tight(size);
    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints);
      final parentData = child.parentData! as ContainerBoxParentData<RenderBox>;
      parentData.offset = Offset.zero;
      child = childAfter(child);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final background = firstChild;
    final foreground = background == null ? null : childAfter(background);
    if (background == null || foreground == null) return;

    final backgroundLayer = _CaptureBackgroundLayer(
        offset: offset, captureBeforeComposition: _captureBackground);
    context.pushLayer(
      backgroundLayer,
      (PaintingContext childContext, Offset childOffset) {
        childContext.paintChild(background, childOffset);
      },
      Offset.zero,
      childPaintBounds: Offset.zero & size,
    );

    context.paintChild(foreground, offset);
  }

  void _captureBackground(OffsetLayer backgroundLayer) {
    if (attached &&
        _handle.captureSupported &&
        _handle._captureClients > 0 &&
        !size.isEmpty) {
      try {
        final captureRect = _captureBounds();
        final image = backgroundLayer.toImageSync(
          captureRect,
          pixelRatio: _capturePixelRatio,
        );
        _handle.replaceImage(image, _capturePixelRatio, captureRect);
      } on Object catch (error, stackTrace) {
        _handle.markUnsupported(error, stackTrace);
      }
    }
  }

  Rect _captureBounds() {
    final scopeBounds = Offset.zero & size;
    Rect? combined;
    for (final client in _handle._clients) {
      try {
        final bounds = client.captureBoundsIn(this).intersect(scopeBounds);
        if (bounds.isEmpty || !bounds.isFinite) continue;
        combined = combined == null ? bounds : combined.expandToInclude(bounds);
      } on Object catch (error) {
        assert(() {
          debugPrint('LiquidGlass client bounds unavailable: $error');
          return true;
        }());
      }
    }
    final bounded = (combined ?? scopeBounds).intersect(scopeBounds);
    if (bounded.isEmpty) return scopeBounds;
    // Keep the texture's sampling lattice anchored to the scope. Rounding only
    // in logical pixels shifts texel centers when the effective ratio is
    // fractional, making identical content change as the union crop expands.
    final ratio = _capturePixelRatio;
    return Rect.fromLTRB(
      (bounded.left * ratio).floorToDouble() / ratio,
      (bounded.top * ratio).floorToDouble() / ratio,
      (bounded.right * ratio).ceilToDouble() / ratio,
      (bounded.bottom * ratio).ceilToDouble() / ratio,
    ).intersect(scopeBounds);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void dispose() {
    _handle._scope = null;
    super.dispose();
  }
}

class _LiquidGlassScopeParentData extends ContainerBoxParentData<RenderBox> {}

/// The framework calls addToScene when this content subtree changes, including
/// a scroll/repaint boundary that updates without repainting the scope itself.
/// A clean subtree retains its engine layer and skips this callback, so an
/// overlay-only animation does not trigger a new capture.
class _CaptureBackgroundLayer extends OffsetLayer {
  _CaptureBackgroundLayer({
    required super.offset,
    required this.captureBeforeComposition,
  });
  final ValueChanged<OffsetLayer> captureBeforeComposition;
  bool _capturing = false;

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (!_capturing) {
      _capturing = true;
      try {
        captureBeforeComposition(this);
      } finally {
        _capturing = false;
      }
    }
    super.addToScene(builder);
  }
}
