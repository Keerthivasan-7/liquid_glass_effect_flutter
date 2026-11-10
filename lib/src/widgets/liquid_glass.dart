import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_accessibility.dart';
import '../geometry/liquid_glass_shape.dart';
import '../geometry/capsule_field.dart';
import '../rendering/capture_footprint.dart';
import '../rendering/liquid_glass_capabilities.dart';
import '../rendering/shader_manager.dart';
import 'liquid_glass_group.dart';
import 'liquid_glass_scope.dart';

// The material axis is constant across every pixel and sampling tap.
Offset _anisotropyAxis(double turns) {
  if (turns == 0) return const Offset(1, 0);
  final angle = turns * math.pi * 2;
  return Offset(math.cos(angle), math.sin(angle));
}

/// A clipped optical surface that refracts the content painted behind it.
///
/// Inside a [LiquidGlassScope], `auto` uses a bounded captured-texture shader.
/// Outside a scope it uses the Impeller image-filter shader when available and
/// otherwise falls back to blur/tint. The foreground [child] remains sharp.
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    required this.child,
    this.config = const LiquidGlassConfig(),
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.shape = const LiquidGlassShape.roundedRectangle(),
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.semanticLabel,
    this.interactive = false,
    this.interactionDuration = const Duration(milliseconds: 180),
    this.lightingController,
    this.onRenderPathChanged,
    super.key,
  });

  final Widget child;
  final LiquidGlassConfig config;

  /// Transparency, contrast, and motion policy for this surface.
  /// An opaque treatment reports [LiquidGlassRenderPath.fallback].
  final LiquidGlassAccessibilityPolicy accessibility;
  final LiquidGlassShape shape;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final String? semanticLabel;

  /// Enables pointer-local optics and restrained hover/press scaling.
  ///
  /// This is visual feedback only and does not consume taps, so interactive
  /// descendants keep their normal gesture and semantic behavior.
  final bool interactive;

  /// Duration used to settle hover and press feedback.
  final Duration interactionDuration;

  /// Optional lighting controller to synchronize dynamic specular highlights with device tilt or cursor.
  final ValueListenable<Offset>? lightingController;

  /// Debug/diagnostic callback fired when the concrete renderer changes.
  final ValueChanged<LiquidGlassRenderPath>? onRenderPathChanged;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass>
    with TickerProviderStateMixin {
  late final AnimationController _animation;
  late final AnimationController _motionSettle;
  static const _waveDuration = Duration(milliseconds: 920);
  final _waveClocks = <AnimationController>[];
  final _waveOrigins = [Offset.zero, Offset.zero];
  var _nextWave = 0;

  _Wave _wave(int i) => (
        origin: _waveOrigins[i],
        age: _waveClocks.isNotEmpty && _waveClocks[i].isAnimating
            ? _waveClocks[i].value * _waveDuration.inMilliseconds / 1000
            : -1,
      );

  void _emitWave(Offset point) {
    if (_reduceMotion || _renderPath == LiquidGlassRenderPath.fallback) return;
    if (_waveClocks.isEmpty) {
      for (var i = 0; i < _waveOrigins.length; i++) {
        _waveClocks
            .add(AnimationController(vsync: this, duration: _waveDuration));
      }
    }
    _waveOrigins[_nextWave] = point;
    _waveClocks[_nextWave].forward(from: 0);
    _nextWave = 1 - _nextWave;
  }

  final GlobalKey _surfaceKey = GlobalKey();
  ui.FragmentShader? _filterShader;
  ui.FragmentShader? _captureShader;
  LiquidGlassCaptureHandle? _captureHandle;
  LiquidGlassMotionHandle? _motionHandle;
  bool _loadingFilter = false;
  bool _loadingCapture = false;
  bool _captureRetained = false;
  LiquidGlassRenderPath? _reportedPath;
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _accessibilityFocused = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  Offset _interactionPoint = Offset.zero;
  Offset _interactionVelocity = Offset.zero;
  Duration? _lastInteractionTime;
  Offset? _dynamicLight;

  LiquidGlassConfig get _effectiveConfig {
    final light = _dynamicLight;
    if (_reduceMotion || light == null || !light.isFinite) return widget.config;
    return widget.config.copyWith(lightDirection: light);
  }

  @override
  void initState() {
    super.initState();
    widget.lightingController?.addListener(_handleLightingChanged);
    _dynamicLight = widget.lightingController?.value;
    _animation = AnimationController(
      vsync: this,
      duration: widget.config.animationDuration,
    );
    _motionSettle = AnimationController(
      vsync: this,
      duration: _settleDuration,
    );
  }

  void _handleLightingChanged() {
    if (mounted) {
      setState(() {
        _dynamicLight = widget.lightingController?.value;
      });
    }
  }

  Duration get _settleDuration => Duration(
        microseconds: math.max(
          widget.interactionDuration.inMicroseconds * 4,
          320000,
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAccessibility();
    final nextHandle = liquidGlassCaptureOf(context);
    if (_captureHandle != nextHandle) {
      if (_captureRetained) _captureHandle?.releaseCapture();
      _captureHandle?.removeListener(_handleChanged);
      _captureHandle = nextHandle;
      _captureHandle?.addListener(_handleChanged);
      _captureRetained = false;
    }
    final nextMotionHandle = liquidGlassMotionOf(context);
    if (_motionHandle != nextMotionHandle) {
      _motionHandle?.removeListener(_handleMotionChanged);
      _motionHandle = nextMotionHandle;
      _motionHandle?.addListener(_handleMotionChanged);
    }
    _syncCaptureRegistration();
    _loadUsefulShaders();
    _synchronizeAnimation();
  }

  void _handleChanged() {
    if (mounted) {
      setState(_syncCaptureRegistration);
      _synchronizeAnimation();
    }
  }

  void _handleMotionChanged() {
    if (mounted && widget.interactive && !_reduceMotion) setState(() {});
  }

  @override
  void didUpdateWidget(covariant LiquidGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lightingController != widget.lightingController) {
      oldWidget.lightingController?.removeListener(_handleLightingChanged);
      widget.lightingController?.addListener(_handleLightingChanged);
      _dynamicLight = widget.lightingController?.value;
    }
    if (oldWidget.config.animationDuration != widget.config.animationDuration) {
      _animation.duration = widget.config.animationDuration;
    }
    if (oldWidget.interactionDuration != widget.interactionDuration) {
      _motionSettle.duration = _settleDuration;
    }
    if (!widget.interactive && oldWidget.interactive) {
      _pressed = false;
      _hovered = false;
      _interactionVelocity = Offset.zero;
      _motionSettle.value = 1;
    }
    if ((oldWidget.shape is CapsuleField) != (widget.shape is CapsuleField) ||
        oldWidget.config.renderer != widget.config.renderer ||
        oldWidget.accessibility != widget.accessibility) {
      _updateAccessibility();
      _syncCaptureRegistration();
      _loadUsefulShaders();
    }
    if (oldWidget.onRenderPathChanged != widget.onRenderPathChanged) {
      _reportedPath = null;
    }
    if (oldWidget.semanticLabel != widget.semanticLabel) {
      _accessibilityFocused = false;
    }
    _synchronizeAnimation();
  }

  void _updateAccessibility() {
    final media = MediaQuery.maybeOf(context);
    _highContrast =
        widget.accessibility.highContrast ?? media?.highContrast ?? false;
    _reduceMotion = widget.accessibility.reduceMotion ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  bool get _usesOpaqueTreatment =>
      widget.accessibility.reduceTransparency || _highContrast;

  bool get _mayUseFilter =>
      widget.shape is! CapsuleField &&
      !_usesOpaqueTreatment &&
      (widget.config.renderer == LiquidGlassRenderer.auto ||
          widget.config.renderer == LiquidGlassRenderer.shader);

  bool get _mayUseCapture =>
      !_usesOpaqueTreatment &&
      (widget.config.renderer == LiquidGlassRenderer.auto ||
          widget.config.renderer == LiquidGlassRenderer.capture);

  void _syncCaptureRegistration() {
    _discardUnusedShaders();
    final shouldRetain =
        _captureHandle?.captureSupported == true && _mayUseCapture;
    if (shouldRetain == _captureRetained) return;
    if (shouldRetain) {
      _captureHandle!.retainCapture();
    } else {
      _captureHandle?.releaseCapture();
    }
    _captureRetained = shouldRetain;
  }

  void _discardUnusedShaders() {
    if (!_mayUseFilter) {
      _filterShader?.dispose();
      _filterShader = null;
    }
    if (!_mayUseCapture || _captureHandle?.captureSupported != true) {
      _captureShader?.dispose();
      _captureShader = null;
    }
  }

  Future<void> _loadUsefulShaders() async {
    if (_mayUseFilter &&
        LiquidGlassCapabilities.supportsShaderBackdropFilter &&
        _filterShader == null &&
        !_loadingFilter) {
      _loadingFilter = true;
      try {
        final program = await LiquidGlassShaderManager.loadFilter();
        if (mounted && _mayUseFilter) {
          setState(() => _filterShader = program.fragmentShader());
          _synchronizeAnimation();
        }
      } on Object catch (error) {
        assert(() {
          debugPrint('LiquidGlass filter shader unavailable: $error');
          return true;
        }());
      } finally {
        _loadingFilter = false;
      }
    }

    if (_mayUseCapture &&
        _captureHandle?.captureSupported == true &&
        _captureShader == null &&
        !_loadingCapture) {
      _loadingCapture = true;
      try {
        final program = await LiquidGlassShaderManager.loadCapture();
        if (mounted &&
            _mayUseCapture &&
            _captureHandle?.captureSupported == true) {
          setState(() => _captureShader = program.fragmentShader());
          _synchronizeAnimation();
        }
      } on Object catch (error) {
        assert(() {
          debugPrint('LiquidGlass capture shader unavailable: $error');
          return true;
        }());
      } finally {
        _loadingCapture = false;
      }
    }
  }

  LiquidGlassRenderPath get _renderPath {
    final handle = _captureHandle;
    if (_mayUseCapture &&
        handle != null &&
        handle.captureSupported &&
        _captureShader != null) {
      return LiquidGlassRenderPath.capture;
    }
    if (_mayUseFilter &&
        LiquidGlassCapabilities.supportsShaderBackdropFilter &&
        _filterShader != null) {
      return LiquidGlassRenderPath.filter;
    }
    return LiquidGlassRenderPath.fallback;
  }

  void _reportRenderPath(LiquidGlassRenderPath path) {
    if (_reportedPath == path) return;
    _reportedPath = path;
    final callback = widget.onRenderPathChanged;
    if (callback == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reportedPath == path) callback(path);
    });
  }

  void _synchronizeAnimation() {
    final shouldAnimate = widget.config.animateLight &&
        widget.config.animationDuration.inMicroseconds > 0 &&
        !_reduceMotion &&
        !_usesOpaqueTreatment &&
        _renderPath != LiquidGlassRenderPath.fallback;
    if (shouldAnimate && !_animation.isAnimating) {
      _animation.repeat();
    } else if (!shouldAnimate && _animation.isAnimating) {
      _animation
        ..stop()
        ..value = 0;
    }
    if (_reduceMotion ||
        !widget.interactive ||
        _renderPath == LiquidGlassRenderPath.fallback) {
      for (final clock in _waveClocks) {
        if (clock.isAnimating) clock.value = 1;
      }
    }
    if (_reduceMotion) {
      _motionSettle
        ..stop()
        ..value = 1;
      _interactionVelocity = Offset.zero;
    }
  }

  @override
  void dispose() {
    widget.lightingController?.removeListener(_handleLightingChanged);
    if (_captureRetained) _captureHandle?.releaseCapture();
    _captureHandle?.removeListener(_handleChanged);
    _motionHandle?.removeListener(_handleMotionChanged);
    for (final clock in _waveClocks) {
      clock.dispose();
    }
    _animation.dispose();
    _motionSettle.dispose();
    _filterShader?.dispose();
    _captureShader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = _reduceMotion;
    final interactionTarget = _pressed
        ? 1.0
        : ((_hovered || _focused || _accessibilityFocused) ? 0.32 : 0.0);
    final scaleTarget = reduceMotion
        ? 1.0
        : _pressed
            ? 0.985
            : _hovered
                ? 1.008
                : 1.0;

    Widget surface = TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : widget.interactionDuration,
      curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
      tween: Tween<double>(end: widget.interactive ? interactionTarget : 0),
      builder: (context, interactionStrength, _) => AnimatedScale(
        scale: widget.interactive && widget.shape is! CapsuleField
            ? scaleTarget
            : 1,
        duration: reduceMotion ? Duration.zero : widget.interactionDuration,
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: _buildSurface(interactionStrength),
      ),
    );

    if (widget.interactive) {
      // Keep the subtree mounted when focus changes. Inserting a new parent
      // here discards the button's internally owned keyboard focus node.
      surface = CustomPaint(
        foregroundPainter: _focused || _accessibilityFocused
            ? _GlassFocusPainter(
                shape: widget.shape, width: _highContrast ? 3 : 2)
            : null,
        child: surface,
      );
      surface = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) {
          if (mounted && _focused != focused) {
            setState(() => _focused = focused);
          }
        },
        child: surface,
      );
      surface = MouseRegion(
        opaque: widget.shape is! CapsuleField,
        hitTestBehavior:
            widget.shape is CapsuleField ? HitTestBehavior.deferToChild : null,
        onEnter: (event) => _trackInteraction(
          point: event.localPosition,
          delta: event.delta,
          timeStamp: event.timeStamp,
          hovered: true,
        ),
        onHover: (event) => _trackInteraction(
          point: event.localPosition,
          delta: event.delta,
          timeStamp: event.timeStamp,
        ),
        onExit: (_) => _releaseInteraction(hovered: false, pressed: false),
        child: Listener(
          behavior: widget.shape is CapsuleField
              ? HitTestBehavior.deferToChild
              : HitTestBehavior.translucent,
          onPointerDown: (event) => _trackInteraction(
            point: event.localPosition,
            delta: event.delta,
            timeStamp: event.timeStamp,
            pressed: true,
          ),
          onPointerMove: (event) => _trackInteraction(
            point: event.localPosition,
            delta: event.delta,
            timeStamp: event.timeStamp,
          ),
          onPointerUp: (event) {
            _trackInteraction(
              point: event.localPosition,
              delta: event.delta,
              timeStamp: event.timeStamp,
            );
            _releaseInteraction(pressed: false);
          },
          onPointerCancel: (_) => _releaseInteraction(pressed: false),
          child: surface,
        ),
      );
    }

    return KeyedSubtree(
      key: _surfaceKey,
      child: Semantics(
        label: widget.semanticLabel,
        container: widget.semanticLabel != null,
        onDidGainAccessibilityFocus:
            widget.interactive && widget.semanticLabel != null
                ? () => setState(() => _accessibilityFocused = true)
                : null,
        onDidLoseAccessibilityFocus:
            widget.interactive && widget.semanticLabel != null
                ? () => setState(() => _accessibilityFocused = false)
                : null,
        child: surface,
      ),
    );
  }

  void _trackInteraction({
    required Offset point,
    required Offset delta,
    required Duration timeStamp,
    bool? hovered,
    bool? pressed,
  }) {
    if (!mounted) return;
    if (pressed == true) _emitWave(point);
    final previousTime = _lastInteractionTime;
    final elapsed = previousTime == null
        ? 0.016
        : (timeStamp - previousTime).inMicroseconds / 1000000;
    final dt = elapsed.clamp(0.001, 0.05);
    final measuredVelocity = delta / dt;
    final nextVelocity = Offset.lerp(
      _interactionVelocity,
      measuredVelocity,
      0.45,
    )!;
    final nextHovered = hovered ?? _hovered;
    final nextPressed = pressed ?? _pressed;
    _motionSettle.stop();
    _motionSettle.value = 0;
    _lastInteractionTime = timeStamp;
    if (point == _interactionPoint &&
        nextVelocity == _interactionVelocity &&
        nextHovered == _hovered &&
        nextPressed == _pressed) {
      return;
    }
    setState(() {
      _interactionPoint = point;
      _interactionVelocity = _reduceMotion ? Offset.zero : nextVelocity;
      _hovered = nextHovered;
      _pressed = nextPressed;
    });
  }

  void _releaseInteraction({bool? hovered, bool? pressed}) {
    if (!mounted) return;
    setState(() {
      _hovered = hovered ?? _hovered;
      _pressed = pressed ?? _pressed;
      _lastInteractionTime = null;
    });
    if (_reduceMotion) {
      _motionSettle
        ..stop()
        ..value = 1;
    } else {
      _motionSettle.forward(from: 0);
    }
  }

  Widget _buildSurface(double interactionStrength) => AnimatedBuilder(
        animation: Listenable.merge(
            <Listenable>[_animation, _motionSettle, ..._waveClocks]),
        builder: (context, _) {
          final path = _renderPath;
          _reportRenderPath(path);
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.hasBoundedWidth ? constraints.maxWidth : 0,
                  constraints.hasBoundedHeight ? constraints.maxHeight : 0,
                );
                Widget foreground = Padding(
                  padding: widget.padding,
                  child: widget.child,
                );
                if (_usesOpaqueTreatment) {
                  final luminance = _opaqueColor.computeLuminance();
                  final foregroundColor =
                      1.05 / (luminance + 0.05) >= (luminance + 0.05) / 0.05
                          ? Colors.white
                          : Colors.black;
                  foreground = DefaultTextStyle.merge(
                    style: TextStyle(color: foregroundColor),
                    child: IconTheme.merge(
                        data: IconThemeData(color: foregroundColor),
                        child: foreground),
                  );
                }
                final motion = _resolveMotion(size, interactionStrength);
                if (path == LiquidGlassRenderPath.capture) {
                  return _CaptureGlassSurface(
                    handle: _captureHandle!,
                    shader: _captureShader!,
                    config: _effectiveConfig,
                    shape: widget.shape,
                    waves: (_wave(0), _wave(1)),
                    animationValue: _animation.value,
                    interactionPoint: motion.point,
                    interactionStrength: motion.interactionStrength,
                    interactionVelocity: motion.velocity,
                    motionStrength: motion.motionStrength,
                    captureAnchor: widget.interactive ? _surfaceKey : null,
                    child: foreground,
                  );
                }
                final filtered = ClipPath(
                  clipper: _LiquidGlassClipper(widget.shape),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      Positioned.fill(
                        child: _buildBackdrop(
                          path,
                          size,
                          motion,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _GlassOverlayPainter(
                              config: _effectiveConfig,
                              shape: widget.shape,
                              applyTint:
                                  path == LiquidGlassRenderPath.fallback &&
                                      !_usesOpaqueTreatment,
                            ),
                          ),
                        ),
                      ),
                      foreground,
                    ],
                  ),
                );
                return filtered;
              },
            ),
          );
        },
      );

  Color get _opaqueColor => (widget.accessibility.opaqueColor ??
          Theme.of(context).colorScheme.surface)
      .withValues(alpha: 1);

  Widget _buildBackdrop(
    LiquidGlassRenderPath path,
    Size size,
    _GlassMotionSample motion,
  ) {
    if (_usesOpaqueTreatment) return ColoredBox(color: _opaqueColor);
    final shader = _filterShader;
    if (path == LiquidGlassRenderPath.filter &&
        shader != null &&
        size.width > 0 &&
        size.height > 0) {
      final pixelRatio = View.of(context).devicePixelRatio;
      return _FilterGlassBackdrop(
        shader: shader,
        prepare: (origin) =>
            _bindFilterUniforms(shader, size, motion, origin, pixelRatio),
      );
    }
    return BackdropFilter(
      filter: ui.ImageFilter.blur(
        sigmaX: _effectiveConfig.blurSigma,
        sigmaY: _effectiveConfig.blurSigma,
        tileMode: TileMode.clamp,
      ),
      child: const SizedBox.expand(),
    );
  }

  void _bindFilterUniforms(
    ui.FragmentShader shader,
    Size size,
    _GlassMotionSample motion,
    Offset screenOrigin,
    double pixelsPerLogical,
  ) {
    final config = _effectiveConfig;
    final light = _animatedLight(config.lightDirection, _animation.value);
    final tint = config.tint;
    final absorption = config.absorptionColor;
    final lightColor = config.lightColor;
    final anisotropyAxis = _anisotropyAxis(config.anisotropyRotation);
    // Slots 0 and 1 (u_size) are populated by the image-filter engine.
    shader
      ..setFloat(2, config.refractionStrength)
      ..setFloat(3, config.fresnelStrength)
      ..setFloat(4, config.specularStrength)
      ..setFloat(5, config.chromaticAberration)
      ..setFloat(6, config.thickness)
      ..setFloat(7, config.curvature)
      ..setFloat(8, config.edgeWidth)
      ..setFloat(9, config.maxDisplacement)
      ..setFloat(10, config.blurSigma)
      ..setFloat(11, config.saturation)
      ..setFloat(12, tint.r)
      ..setFloat(13, tint.g)
      ..setFloat(14, tint.b)
      ..setFloat(15, tint.a)
      ..setFloat(16, light.dx)
      ..setFloat(17, light.dy)
      ..setFloat(18, config.noise)
      ..setFloat(19, config.quality.index.toDouble())
      ..setFloat(20, widget.shape.resolvedRadius(size))
      ..setFloat(21, widget.shape.shaderValue)
      ..setFloat(22, _animation.value)
      ..setFloat(23, motion.point.dx)
      ..setFloat(24, motion.point.dy)
      ..setFloat(25, motion.interactionStrength)
      ..setFloat(26, config.refractiveIndex)
      ..setFloat(27, config.cornerSmoothing)
      ..setFloat(28, config.innerShadow)
      ..setFloat(29, config.roughness)
      ..setFloat(30, config.transmission)
      ..setFloat(31, absorption.r)
      ..setFloat(32, absorption.g)
      ..setFloat(33, absorption.b)
      ..setFloat(34, absorption.a)
      ..setFloat(35, config.absorptionStrength)
      ..setFloat(36, config.scatteringStrength)
      ..setFloat(37, config.dispersionStrength)
      ..setFloat(38, config.abbeNumber)
      ..setFloat(39, config.environmentStrength)
      ..setFloat(40, config.coatStrength)
      ..setFloat(41, config.coatRoughness)
      ..setFloat(42, config.coatRefractiveIndex)
      ..setFloat(43, config.thinFilmThickness)
      ..setFloat(44, config.thinFilmRefractiveIndex)
      ..setFloat(45, config.thinFilmStrength)
      ..setFloat(46, config.anisotropy)
      ..setFloat(47, anisotropyAxis.dx)
      ..setFloat(48, anisotropyAxis.dy)
      ..setFloat(49, config.causticStrength)
      ..setFloat(50, lightColor.r)
      ..setFloat(51, lightColor.g)
      ..setFloat(52, lightColor.b)
      ..setFloat(53, lightColor.a)
      ..setFloat(54, config.lightIntensity)
      ..setFloat(55, motion.velocity.dx)
      ..setFloat(56, motion.velocity.dy)
      ..setFloat(57, motion.motionStrength)
      ..setFloat(58, screenOrigin.dx * pixelsPerLogical)
      ..setFloat(59, screenOrigin.dy * pixelsPerLogical)
      ..setFloat(60, size.width)
      ..setFloat(61, size.height)
      ..setFloat(62, pixelsPerLogical)
      ..setFloat(63, config.vibrancy)
      ..setFloat(64, _wave(0).origin.dx)
      ..setFloat(65, _wave(0).origin.dy)
      ..setFloat(66, _wave(0).age)
      ..setFloat(67, _wave(1).origin.dx)
      ..setFloat(68, _wave(1).origin.dy)
      ..setFloat(69, _wave(1).age);
  }

  _GlassMotionSample _resolveMotion(Size size, double interactionStrength) {
    if (_reduceMotion) {
      return _GlassMotionSample(
          point: size.center(Offset.zero),
          velocity: Offset.zero,
          interactionStrength: 0,
          motionStrength: 0);
    }
    final settle = 1 - Curves.easeOutCubic.transform(_motionSettle.value);
    var point = (_focused || _accessibilityFocused) && !_hovered && !_pressed
        ? size.center(Offset.zero)
        : _interactionPoint;
    var velocity = _normalizeVelocity(_interactionVelocity * settle, size);
    var strength = interactionStrength;

    final handle = _motionHandle;
    final box = _surfaceKey.currentContext?.findRenderObject();
    if (widget.interactive &&
        handle != null &&
        box is RenderBox &&
        box.hasSize) {
      final field = handle.motion;
      final localPoint = box.globalToLocal(field.globalPosition);
      final bounds = Offset.zero & box.size;
      final nearest = Offset(
        localPoint.dx.clamp(bounds.left, bounds.right),
        localPoint.dy.clamp(bounds.top, bounds.bottom),
      );
      final distance = (localPoint - nearest).distance;
      final radius = handle.influenceRadius;
      final influence = math.exp(-2.4 * math.pow(distance / radius, 2));
      final groupStrength = field.strength * influence;
      if (groupStrength > 0.001) {
        final localVelocity = box.globalToLocal(
              field.globalPosition + field.velocity,
            ) -
            localPoint;
        final normalizedGroupVelocity = _normalizeVelocity(localVelocity, size);
        final total = math.max(strength + groupStrength, 0.0001);
        velocity =
            (velocity * strength + normalizedGroupVelocity * groupStrength) /
                total;
        point = Offset.lerp(point, localPoint, groupStrength / total)!;
        strength = (math.max(strength, groupStrength) +
                math.min(strength, groupStrength) * 0.28)
            .clamp(0, 1.5);
      }
    }

    return _GlassMotionSample(
      point: point,
      velocity: velocity,
      interactionStrength: strength,
      motionStrength: strength * widget.config.motionStrength,
    );
  }

  Offset _normalizeVelocity(Offset velocity, Size size) {
    final shortest = math.max(math.min(size.width, size.height), 1);
    final scale = shortest * 14;
    return Offset(
      (velocity.dx / scale).clamp(-1.5, 1.5),
      (velocity.dy / scale).clamp(-1.5, 1.5),
    );
  }

  Offset _animatedLight(Offset light, double animationValue) {
    if (!widget.config.animateLight) return light;
    final angle = animationValue * math.pi * 2;
    return Offset(
      light.dx * math.cos(angle) - light.dy * math.sin(angle),
      light.dx * math.sin(angle) + light.dy * math.cos(angle),
    );
  }
}

class _FilterGlassBackdrop extends SingleChildRenderObjectWidget {
  const _FilterGlassBackdrop({required this.shader, required this.prepare})
      : super(child: const SizedBox.expand());
  final ui.FragmentShader shader;
  final ValueChanged<Offset> prepare;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFilterGlassBackdrop(shader, prepare);
  @override
  void updateRenderObject(
      BuildContext context, _RenderFilterGlassBackdrop renderObject) {
    renderObject
      ..shader = shader
      ..prepare = prepare
      ..markNeedsPaint();
  }
}

class _RenderFilterGlassBackdrop extends RenderProxyBox {
  _RenderFilterGlassBackdrop(this.shader, this.prepare);
  ui.FragmentShader shader;
  ValueChanged<Offset> prepare;
  @override
  bool get alwaysNeedsCompositing => true;
  @override
  void paint(PaintingContext context, Offset offset) {
    final backdrop = layer as _FilterGlassLayer? ?? _FilterGlassLayer();
    backdrop.prepare = () {
      if (!attached) return;
      // Resolve retained scroll offsets at composition, rather than build time.
      prepare(localToGlobal(Offset.zero));
      backdrop.filter = ui.ImageFilter.shader(shader);
    };
    layer = backdrop;
    context.pushLayer(backdrop, super.paint, offset);
  }
}

class _FilterGlassLayer extends BackdropFilterLayer {
  VoidCallback? prepare;
  @override
  bool get alwaysNeedsAddToScene => true;
  @override
  void addToScene(ui.SceneBuilder builder) {
    prepare?.call();
    super.addToScene(builder);
  }

  @override
  void dispose() {
    prepare = null;
    super.dispose();
  }
}

typedef _Wave = ({Offset origin, double age});
typedef _Waves = (_Wave, _Wave);

class _CaptureGlassSurface extends SingleChildRenderObjectWidget {
  const _CaptureGlassSurface({
    required this.handle,
    required this.shader,
    required this.config,
    required this.shape,
    required this.animationValue,
    required this.waves,
    required this.interactionPoint,
    required this.interactionStrength,
    required this.interactionVelocity,
    required this.motionStrength,
    this.captureAnchor,
    required super.child,
  });

  final LiquidGlassCaptureHandle handle;
  final ui.FragmentShader shader;
  final LiquidGlassConfig config;
  final LiquidGlassShape shape;
  final double animationValue;
  final _Waves waves;
  final Offset interactionPoint;
  final double interactionStrength;
  final Offset interactionVelocity;
  final double motionStrength;
  final GlobalKey? captureAnchor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCaptureGlassSurface(
        handle: handle,
        shader: shader,
        config: config,
        shape: shape,
        animationValue: animationValue,
        waves: waves,
        interactionPoint: interactionPoint,
        interactionStrength: interactionStrength,
        interactionVelocity: interactionVelocity,
        motionStrength: motionStrength,
        captureAnchor: captureAnchor,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderCaptureGlassSurface renderObject,
  ) {
    renderObject
      ..handle = handle
      ..shader = shader
      ..config = config
      ..shape = shape
      ..waves = waves
      ..animationValue = animationValue
      ..interactionPoint = interactionPoint
      ..interactionStrength = interactionStrength
      ..interactionVelocity = interactionVelocity
      ..motionStrength = motionStrength;
    renderObject.captureAnchor = captureAnchor;
  }
}

class _RenderCaptureGlassSurface extends RenderProxyBox
    implements LiquidGlassCaptureClient {
  @override
  bool get alwaysNeedsCompositing => true;

  _RenderCaptureGlassSurface({
    required LiquidGlassCaptureHandle handle,
    required ui.FragmentShader shader,
    required LiquidGlassConfig config,
    required LiquidGlassShape shape,
    required double animationValue,
    required _Waves waves,
    required Offset interactionPoint,
    required double interactionStrength,
    required Offset interactionVelocity,
    required double motionStrength,
    GlobalKey? captureAnchor,
  })  : _handle = handle,
        _shader = shader,
        _config = config,
        _shape = shape,
        _waves = waves,
        _animationValue = animationValue,
        _interactionPoint = interactionPoint,
        _interactionStrength = interactionStrength,
        _interactionVelocity = interactionVelocity,
        _motionStrength = motionStrength,
        _captureAnchor = captureAnchor;

  LiquidGlassCaptureHandle _handle;
  ui.FragmentShader _shader;
  LiquidGlassConfig _config;
  LiquidGlassShape _shape;
  _Waves _waves;

  set waves(_Waves value) {
    if (_waves == value) return;
    _waves = value;
    markNeedsPaint();
  }

  double _animationValue;
  Offset _interactionPoint;
  double _interactionStrength;
  Offset _interactionVelocity;
  double _motionStrength;
  GlobalKey? _captureAnchor;

  // Bounds the .985 -> 1.008 release, including easeOutBack overshoot.
  static const _maxInteractiveCaptureScale = 1.011;

  set captureAnchor(GlobalKey? value) {
    if (_captureAnchor == value) return;
    _captureAnchor = value;
    _handle.requestCapture();
    markNeedsPaint();
  }

  set handle(LiquidGlassCaptureHandle value) {
    if (_handle == value) return;
    if (attached) _handle.unregisterClient(this);
    _handle = value;
    if (attached) _handle.registerClient(this);
    markNeedsPaint();
  }

  set shader(ui.FragmentShader value) {
    if (_shader == value) return;
    _shader = value;
    markNeedsPaint();
  }

  set config(LiquidGlassConfig value) {
    if (_config == value) return;
    _config = value;
    _handle.requestCapture();
    markNeedsPaint();
  }

  set shape(LiquidGlassShape value) {
    if (_shape == value) return;
    _shape = value;
    markNeedsPaint();
  }

  set animationValue(double value) {
    if (_animationValue == value) return;
    _animationValue = value;
    markNeedsPaint();
  }

  set interactionPoint(Offset value) {
    if (_interactionPoint == value) return;
    _interactionPoint = value;
    markNeedsPaint();
  }

  set interactionStrength(double value) {
    if (_interactionStrength == value) return;
    _interactionStrength = value;
    markNeedsPaint();
  }

  set interactionVelocity(Offset value) {
    if (_interactionVelocity == value) return;
    _interactionVelocity = value;
    markNeedsPaint();
  }

  set motionStrength(double value) {
    if (_motionStrength == value) return;
    _motionStrength = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _handle.registerClient(this);
  }

  @override
  void detach() {
    _handle.unregisterClient(this);
    super.detach();
  }

  @override
  Rect captureBoundsIn(RenderBox scope) {
    if (!attached || !hasSize || size.isEmpty) return Rect.zero;
    final transform = getTransformTo(scope);
    final footprint = liquidGlassCaptureFootprint(
      config: _config,
      surfaceSize: size,
      capturePixelRatio: _handle.requestedPixelRatio,
    );
    final samplingReach =
        math.max(footprint.transmissionReach, footprint.reflectionReach);
    final anchor = _captureAnchor?.currentContext?.findRenderObject();
    final Rect bounds;
    if (anchor is RenderBox && anchor.attached && anchor.hasSize) {
      // Anchor outside AnimatedScale so the required crop stays stable during
      // hover/press. Reuse the existing image throughout the known animation
      // envelope instead of capturing again for each scale change.
      final sampleBounds = Rect.fromCenter(
        center: anchor.size.center(Offset.zero),
        width: (size.width + samplingReach * 2) * _maxInteractiveCaptureScale,
        height: (size.height + samplingReach * 2) * _maxInteractiveCaptureScale,
      );
      bounds =
          MatrixUtils.transformRect(anchor.getTransformTo(scope), sampleBounds);
    } else {
      bounds = MatrixUtils.transformRect(
          transform, (Offset.zero & size).inflate(samplingReach));
    }
    final rasterGuard = footprint.logicalPadding - samplingReach;
    return bounds.inflate(rasterGuard).intersect(Offset.zero & scope.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Capture is refreshed by the scope after retained foreground boundaries
    // may already have painted. Resolve the optical picture during scene
    // composition so it always samples the current generation in that frame.
    context.addLayer(_CaptureGlassLayer(() {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      if (attached && hasSize) _paintOptics(canvas, offset);
      return recorder.endRecording();
    }, () {
      final scope = _handle.scopeRenderBox;
      if (!attached || scope == null || !scope.attached) return null;
      final matrix = getTransformTo(scope).storage;
      return (
        _handle.image,
        matrix[0],
        matrix[1],
        matrix[4],
        matrix[5],
        matrix[12],
        matrix[13],
      );
    }));

    final foreground = child;
    if (foreground != null) {
      context.pushClipPath(
        needsCompositing,
        offset,
        Offset.zero & size,
        _shape.pathFor(size),
        (childContext, childOffset) {
          childContext.paintChild(foreground, childOffset);
        },
        clipBehavior: Clip.antiAlias,
      );
    }
  }

  void _paintOptics(Canvas canvas, Offset offset) {
    final path = _shape.pathFor(size);
    final image = _handle.image;
    final scope = _handle.scopeRenderBox;
    var shaderPainted = false;

    if (image != null && scope != null && scope.attached && !size.isEmpty) {
      try {
        final requiredBounds = captureBoundsIn(scope);
        final captureRect = _handle.captureRect;
        if (!_containsRect(captureRect, requiredBounds)) {
          _handle.requestCapture();
        } else {
          final transform = getTransformTo(scope);
          final scopeOrigin =
              MatrixUtils.transformPoint(transform, Offset.zero);
          final captureOrigin = scopeOrigin - captureRect.topLeft;
          // toImageSync rounds texture dimensions up to whole pixels. Use the
          // resulting logical extent so fractional DPR/quality scales do not
          // stretch the sampled content back into the requested crop size.
          final textureLogicalSize = Size(
            image.width / _handle.pixelRatio,
            image.height / _handle.pixelRatio,
          );
          _bindCaptureUniforms(
              captureOrigin, textureLogicalSize, image, transform.storage);
          canvas
            ..save()
            ..translate(offset.dx, offset.dy)
            ..drawPath(
                _shape is CapsuleField
                    ? (Path()..addRect(Offset.zero & size))
                    : path,
                Paint()..shader = _shader)
            ..restore();
          shaderPainted = true;
        }
      } on Object catch (error, stackTrace) {
        _handle.markUnsupported(error, stackTrace);
      }
    }

    if (!shaderPainted) {
      canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..drawPath(path, Paint()..color = _config.tint)
        ..restore();
    }
  }

  bool _containsRect(Rect outer, Rect inner) {
    const tolerance = 0.01;
    return !outer.isEmpty &&
        inner.left >= outer.left - tolerance &&
        inner.top >= outer.top - tolerance &&
        inner.right <= outer.right + tolerance &&
        inner.bottom <= outer.bottom + tolerance;
  }

  void _bindCaptureUniforms(Offset origin, Size scopeSize, ui.Image image,
      List<double> surfaceTransform) {
    final tint = _config.tint;
    final light = _animatedLight(_config.lightDirection);
    final field = _shape is CapsuleField ? _shape as CapsuleField : null;
    final absorption = _config.absorptionColor;
    final lightColor = _config.lightColor;
    final anisotropyAxis = _anisotropyAxis(_config.anisotropyRotation);
    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, scopeSize.width)
      ..setFloat(3, scopeSize.height)
      ..setFloat(4, origin.dx)
      ..setFloat(5, origin.dy)
      ..setFloat(6, _config.refractiveIndex)
      ..setFloat(7, _config.refractionStrength)
      ..setFloat(8, _config.fresnelStrength)
      ..setFloat(9, _config.specularStrength)
      ..setFloat(10, _config.chromaticAberration)
      ..setFloat(11, _config.thickness)
      ..setFloat(12, _config.curvature)
      ..setFloat(13, _config.cornerSmoothing)
      ..setFloat(14, _config.edgeWidth)
      ..setFloat(15, _config.maxDisplacement)
      ..setFloat(16, _config.blurSigma)
      ..setFloat(17, _config.saturation)
      ..setFloat(18, tint.r)
      ..setFloat(19, tint.g)
      ..setFloat(20, tint.b)
      ..setFloat(21, tint.a)
      ..setFloat(22, light.dx)
      ..setFloat(23, light.dy)
      ..setFloat(24, _config.noise)
      ..setFloat(25, _config.quality.index.toDouble())
      ..setFloat(26, _shape.resolvedRadius(size))
      ..setFloat(27, _shape.shaderValue)
      ..setFloat(28, _animationValue)
      ..setFloat(29, _interactionPoint.dx)
      ..setFloat(30, _interactionPoint.dy)
      ..setFloat(31, _interactionStrength)
      ..setFloat(32, _config.innerShadow)
      ..setFloat(33, _config.roughness)
      ..setFloat(34, _config.transmission)
      ..setFloat(35, absorption.r)
      ..setFloat(36, absorption.g)
      ..setFloat(37, absorption.b)
      ..setFloat(38, absorption.a)
      ..setFloat(39, _config.absorptionStrength)
      ..setFloat(40, _config.scatteringStrength)
      ..setFloat(41, _config.dispersionStrength)
      ..setFloat(42, _config.abbeNumber)
      ..setFloat(43, _config.environmentStrength)
      ..setFloat(44, _config.coatStrength)
      ..setFloat(45, _config.coatRoughness)
      ..setFloat(46, _config.coatRefractiveIndex)
      ..setFloat(47, _config.thinFilmThickness)
      ..setFloat(48, _config.thinFilmRefractiveIndex)
      ..setFloat(49, _config.thinFilmStrength)
      ..setFloat(50, _config.anisotropy)
      ..setFloat(51, anisotropyAxis.dx)
      ..setFloat(52, anisotropyAxis.dy)
      ..setFloat(53, _config.causticStrength)
      ..setFloat(54, lightColor.r)
      ..setFloat(55, lightColor.g)
      ..setFloat(56, lightColor.b)
      ..setFloat(57, lightColor.a)
      ..setFloat(58, _config.lightIntensity)
      ..setFloat(59, _interactionVelocity.dx)
      ..setFloat(60, _interactionVelocity.dy)
      ..setFloat(61, _motionStrength)
      ..setFloat(62, image.width.toDouble())
      ..setFloat(63, image.height.toDouble())
      ..setFloat(64, surfaceTransform[0])
      ..setFloat(65, surfaceTransform[1])
      ..setFloat(66, surfaceTransform[4])
      ..setFloat(67, surfaceTransform[5])
      ..setFloat(68, _config.vibrancy)
      ..setFloat(69, _waves.$1.origin.dx)
      ..setFloat(70, _waves.$1.origin.dy)
      ..setFloat(71, _waves.$1.age)
      ..setFloat(72, _waves.$2.origin.dx)
      ..setFloat(73, _waves.$2.origin.dy)
      ..setFloat(74, _waves.$2.age)
      ..setFloat(75, field?.blendRadius ?? 0)
      ..setFloat(76, field?.member(0).left ?? 0)
      ..setFloat(77, field?.member(0).top ?? 0)
      ..setFloat(78, field?.member(0).width ?? 0)
      ..setFloat(79, field?.member(0).height ?? 0)
      ..setFloat(80, field?.member(1).left ?? 0)
      ..setFloat(81, field?.member(1).top ?? 0)
      ..setFloat(82, field?.member(1).width ?? 0)
      ..setFloat(83, field?.member(1).height ?? 0)
      ..setFloat(84, field?.member(2).left ?? 0)
      ..setFloat(85, field?.member(2).top ?? 0)
      ..setFloat(86, field?.member(2).width ?? 0)
      ..setFloat(87, field?.member(2).height ?? 0)
      ..setFloat(88, field?.member(3).left ?? 0)
      ..setFloat(89, field?.member(3).top ?? 0)
      ..setFloat(90, field?.member(3).width ?? 0)
      ..setFloat(91, field?.member(3).height ?? 0)
      ..setImageSampler(0, image);
  }

  Offset _animatedLight(Offset light) {
    if (!_config.animateLight) return light;
    final angle = _animationValue * math.pi * 2;
    return Offset(
      light.dx * math.cos(angle) - light.dy * math.sin(angle),
      light.dx * math.sin(angle) + light.dy * math.cos(angle),
    );
  }
}

/// Re-records only the optical draw when a retained scene is composed.
/// Foreground children retain their ordinary Flutter painting lifecycle.
class _CaptureGlassLayer extends Layer {
  _CaptureGlassLayer(this.recordPicture, this.pictureIdentity);

  final ui.Picture Function() recordPicture;
  final Object? Function() pictureIdentity;
  ui.Picture? _picture;
  Object? _identity;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    final identity = pictureIdentity();
    if (_picture == null || identity != _identity) {
      final previous = _picture;
      _picture = recordPicture();
      _identity = identity;
      if (previous != null) _retireOpticalPicture(previous);
    }
    builder.addPicture(Offset.zero, _picture!);
  }

  @override
  void dispose() {
    final picture = _picture;
    if (picture != null) _retireOpticalPicture(picture);
    _picture = null;
    super.dispose();
  }
}

void _retireOpticalPicture(ui.Picture picture) {
  // A readback and the visible scene can share retained engine layers.
  // skwasm can still inspect an older picture while resolving that scene.
  // Keep it through two completed frames, just like capture images. Unchanged
  // optical pictures are cached above, so these guard frames cannot create an
  // idle retirement/repaint loop.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    SchedulerBinding.instance.addPostFrameCallback((_) => picture.dispose());
    SchedulerBinding.instance.ensureVisualUpdate();
  });
  SchedulerBinding.instance.ensureVisualUpdate();
}

@immutable
class _GlassMotionSample {
  const _GlassMotionSample({
    required this.point,
    required this.velocity,
    required this.interactionStrength,
    required this.motionStrength,
  });

  final Offset point;
  final Offset velocity;
  final double interactionStrength;
  final double motionStrength;
}

class _LiquidGlassClipper extends CustomClipper<Path> {
  const _LiquidGlassClipper(this.shape);

  final LiquidGlassShape shape;

  @override
  Path getClip(Size size) => shape.pathFor(size);

  @override
  bool shouldReclip(_LiquidGlassClipper oldClipper) =>
      oldClipper.shape != shape;
}

class _GlassFocusPainter extends CustomPainter {
  const _GlassFocusPainter({required this.shape, required this.width});
  final LiquidGlassShape shape;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 6 || size.height <= 6) return;
    final path = shape.pathFor(Size(size.width - 6, size.height - 6));
    canvas
      ..save()
      ..translate(3, 3)
      ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width + 2
            ..color = Colors.black)
      ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = Colors.white)
      ..restore();
  }

  @override
  bool shouldRepaint(_GlassFocusPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.width != width;
}

class _GlassOverlayPainter extends CustomPainter {
  const _GlassOverlayPainter({
    required this.config,
    required this.shape,
    required this.applyTint,
  });

  final LiquidGlassConfig config;
  final LiquidGlassShape shape;
  final bool applyTint;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = shape.pathFor(size);
    if (applyTint) canvas.drawPath(path, Paint()..color = config.tint);
    if (config.borderWidth <= 0) return;

    final light = config.lightDirection;
    final begin = Alignment(light.dx.clamp(-1, 1), light.dy.clamp(-1, 1));
    final end = Alignment(-begin.x, -begin.y);
    final shader = LinearGradient(
      begin: begin,
      end: end,
      colors: <Color>[
        Colors.white.withValues(alpha: 0.34),
        Colors.white.withValues(alpha: 0.025),
        Colors.black.withValues(alpha: 0.08),
      ],
      stops: const <double>[0, 0.58, 1],
    ).createShader(Offset.zero & size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.borderWidth
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_GlassOverlayPainter oldDelegate) =>
      oldDelegate.config != config ||
      oldDelegate.shape != shape ||
      oldDelegate.applyTint != applyTint;
}
