import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart' as meta;

/// A shared, velocity-aware interaction field for nearby glass surfaces.
///
/// Place related [LiquidGlass] controls below this widget to make pointer and
/// touch motion flow across the complete control cluster. It does not compete
/// in Flutter's gesture arena, so buttons, sliders, and scroll views retain
/// their normal behavior.
class LiquidGlassGroup extends StatefulWidget {
  const LiquidGlassGroup({
    required this.child,
    this.influenceRadius = 180,
    this.motionGain = 1,
    this.settleDuration = const Duration(milliseconds: 720),
    super.key,
  })  : assert(influenceRadius > 0),
        assert(motionGain >= 0 && motionGain <= 3),
        assert(settleDuration > Duration.zero);

  final Widget child;

  /// Logical-pixel radius over which one surface influences its siblings.
  final double influenceRadius;

  /// Multiplier applied to the field's velocity and spring energy.
  final double motionGain;

  /// Approximate time for released motion to become visually still.
  final Duration settleDuration;

  @override
  State<LiquidGlassGroup> createState() => _LiquidGlassGroupState();
}

@immutable
class LiquidGlassMotion {
  const LiquidGlassMotion({
    required this.globalPosition,
    required this.velocity,
    required this.strength,
    required this.active,
  });

  static const zero = LiquidGlassMotion(
    globalPosition: Offset.zero,
    velocity: Offset.zero,
    strength: 0,
    active: false,
  );

  final Offset globalPosition;

  /// Smoothed global velocity in logical pixels per second.
  final Offset velocity;

  final double strength;
  final bool active;
}

/// Internal group state consumed by [LiquidGlass].
@meta.internal
class LiquidGlassMotionHandle extends ChangeNotifier {
  LiquidGlassMotion _motion = LiquidGlassMotion.zero;
  double _influenceRadius = 180;
  double _motionGain = 1;

  LiquidGlassMotion get motion => _motion;
  double get influenceRadius => _influenceRadius;
  double get motionGain => _motionGain;

  void update(
    LiquidGlassMotion motion, {
    required double influenceRadius,
    required double motionGain,
  }) {
    if (_motion == motion &&
        _influenceRadius == influenceRadius &&
        _motionGain == motionGain) {
      return;
    }
    _motion = motion;
    _influenceRadius = influenceRadius;
    _motionGain = motionGain;
    notifyListeners();
  }
}

class _LiquidGlassGroupState extends State<LiquidGlassGroup>
    with SingleTickerProviderStateMixin {
  late final LiquidGlassMotionHandle _handle;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  Duration? _lastEventTime;
  int? _primaryPointer;
  Offset _position = Offset.zero;
  Offset _velocity = Offset.zero;
  double _strength = 0;
  double _strengthVelocity = 0;
  bool _hovering = false;
  bool _pressed = false;

  bool get _active => _hovering || _pressed;

  @override
  void initState() {
    super.initState();
    _handle = LiquidGlassMotionHandle();
    _ticker = createTicker(_tick);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publish();
  }

  void _ingest(PointerEvent event, {bool? pressed}) {
    if (pressed != null) _pressed = pressed;
    final eventTime = event.timeStamp;
    final previousTime = _lastEventTime;
    final elapsed = previousTime == null
        ? 0.016
        : (eventTime - previousTime).inMicroseconds / 1000000;
    final dt = elapsed.clamp(0.001, 0.05);
    final measured = event.delta / dt;
    _velocity = Offset.lerp(_velocity, measured, 0.42)!;
    _position = event.position;
    _lastEventTime = eventTime;
    _strength = math.max(_strength, 0.18);
    _strengthVelocity = math.max(_strengthVelocity, 0);
    _ensureTicking();
    _publish();
  }

  void _release(PointerEvent event) {
    _position = event.position;
    _pressed = false;
    _primaryPointer = null;
    _lastEventTime = null;
    _ensureTicking();
    _publish();
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final rawDt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    final dt = rawDt.clamp(0.001, 0.034);
    final settleSeconds = math.max(
      widget.settleDuration.inMicroseconds / 1000000,
      0.12,
    );

    if (_active) {
      final response = 1 - math.exp(-dt * 18);
      _strength += (1 - _strength) * response;
      _strengthVelocity = 0;
      _velocity *= math.exp(-dt * 4.5);
    } else {
      // Critically damped spring toward zero, followed by an inertial wake.
      final angularFrequency = 5.8 / settleSeconds;
      final acceleration = -angularFrequency * angularFrequency * _strength -
          2 * angularFrequency * _strengthVelocity;
      _strengthVelocity += acceleration * dt;
      _strength = math.max(0, _strength + _strengthVelocity * dt);
      _velocity *= math.exp(-dt * 6.2 / settleSeconds);
      _position += _velocity * dt * 0.12;
    }

    _publish();
    if (_active && _strength > 0.998 && _velocity.distance < 0.5) {
      _ticker.stop();
      _lastTick = Duration.zero;
      return;
    }
    if (!_active && _strength < 0.002 && _velocity.distance < 0.5) {
      _strength = 0;
      _strengthVelocity = 0;
      _velocity = Offset.zero;
      _publish();
      _ticker.stop();
      _lastTick = Duration.zero;
    }
  }

  void _publish() {
    _handle.update(
      LiquidGlassMotion(
        globalPosition: _position,
        velocity: _velocity * widget.motionGain,
        strength: (_strength * widget.motionGain).clamp(0, 1.5),
        active: _active,
      ),
      influenceRadius: widget.influenceRadius,
      motionGain: widget.motionGain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion = (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    return _LiquidGlassMotionInherited(
      handle: _handle,
      child: MouseRegion(
        onEnter: (event) {
          _hovering = !reduceMotion;
          if (_hovering) _ingest(event);
        },
        onExit: (_) {
          _hovering = false;
          _lastEventTime = null;
          if (reduceMotion) {
            _strength = 0;
            _velocity = Offset.zero;
            _publish();
          } else {
            _ensureTicking();
          }
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: reduceMotion ? null : _ingest,
          onPointerDown: (event) {
            if (_primaryPointer != null || reduceMotion) return;
            _primaryPointer = event.pointer;
            _ingest(event, pressed: true);
          },
          onPointerMove: (event) {
            if (_primaryPointer == event.pointer && !reduceMotion) {
              _ingest(event);
            }
          },
          onPointerUp: (event) {
            if (_primaryPointer == event.pointer) _release(event);
          },
          onPointerCancel: (event) {
            if (_primaryPointer == event.pointer) _release(event);
          },
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _handle.dispose();
    super.dispose();
  }
}

class _LiquidGlassMotionInherited extends InheritedWidget {
  const _LiquidGlassMotionInherited({
    required this.handle,
    required super.child,
  });

  final LiquidGlassMotionHandle handle;

  @override
  bool updateShouldNotify(_LiquidGlassMotionInherited oldWidget) =>
      oldWidget.handle != handle;
}

/// Internal non-listening lookup used by [LiquidGlass].
@meta.internal
LiquidGlassMotionHandle? liquidGlassMotionOf(BuildContext context) => context
    .getInheritedWidgetOfExactType<_LiquidGlassMotionInherited>()
    ?.handle;
