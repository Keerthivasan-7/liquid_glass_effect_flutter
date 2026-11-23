import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import 'liquid_glass_cluster.dart';

typedef _Geometry = ({Rect bounds, double angle, double radius});

_Geometry _geometry(LiquidGlassMember member) => (
      bounds: member.bounds,
      angle: member.rotation,
      radius: (member.borderRadius ?? member.bounds.shortestSide / 2)
          .clamp(0, member.bounds.shortestSide / 2),
    );

/// Animates geometry changes of members with matching IDs.
///
/// Interrupted transitions continue from their displayed geometry. Rotation
/// follows the shortest arc. Newly added members appear at their target bounds;
/// removed members leave immediately. List order controls optical union order
/// and foreground stacking. Foreground content updates immediately.
///
/// Material and lighting changes are applied immediately. Reduced motion follows
/// both [accessibility] and MediaQuery. Like [LiquidGlassCluster], this widget
/// needs bounded layout constraints and a capture scene for merged optics.
class AnimatedLiquidGlassCluster extends StatefulWidget {
  const AnimatedLiquidGlassCluster({
    required this.members,
    this.duration = const Duration(milliseconds: 360),
    this.curve = Curves.easeInOutCubic,
    this.blendRadius = 32,
    this.config = const LiquidGlassConfig.clear(),
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.onRenderPathChanged,
    this.onEnd,
    super.key,
  }) : assert(blendRadius >= 0 && blendRadius < double.infinity);

  final List<LiquidGlassMember> members;
  final Duration duration;
  final Curve curve;
  final double blendRadius;
  final LiquidGlassConfig config;
  final LiquidGlassAccessibilityPolicy accessibility;
  final ValueListenable<Offset>? lightingController;
  final ValueChanged<LiquidGlassRenderPath>? onRenderPathChanged;

  /// Called after an animated transition reaches its destination.
  final VoidCallback? onEnd;

  @override
  State<AnimatedLiquidGlassCluster> createState() => _AnimatedClusterState();
}

class _AnimatedClusterState extends State<AnimatedLiquidGlassCluster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Map<Object, _Geometry> _from = {};
  Map<Object, _Geometry> _to = {};
  late double _fromBlend;
  late double _toBlend;
  late Curve _curve;

  bool get _quiet {
    final media = MediaQuery.maybeOf(context);
    return widget.accessibility.reduceMotion ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  double get _progress => _curve.transform(_controller.value).clamp(0, 1);

  @override
  void initState() {
    super.initState();
    _to = _targets();
    _from = _to;
    _fromBlend = _toBlend = widget.blendRadius;
    _curve = widget.curve;
    _controller =
        AnimationController(vsync: this, duration: widget.duration, value: 1);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.isCompleted) widget.onEnd?.call();
        });
      }
    });
  }

  Map<Object, _Geometry> _targets() {
    if (widget.duration.isNegative) {
      throw ArgumentError.value(
          widget.duration, 'duration', 'Must be nonnegative');
    }
    final result = <Object, _Geometry>{};
    for (final member in widget.members) {
      if (!member.bounds.isFinite ||
          member.bounds.isEmpty ||
          !member.rotation.isFinite ||
          (member.borderRadius != null &&
              (!member.borderRadius!.isFinite || member.borderRadius! < 0)) ||
          result.containsKey(member.id)) {
        throw ArgumentError(
            'Animated members require unique IDs and finite, positive geometry.');
      }
      result[member.id] = _geometry(member);
    }
    return result;
  }

  _Geometry _sample(Object id, double t) {
    final end = _to[id]!;
    final begin = _from[id] ?? end;
    final turn = (end.angle - begin.angle + math.pi) % (2 * math.pi) - math.pi;
    return (
      bounds: Rect.lerp(begin.bounds, end.bounds, t)!,
      angle: begin.angle + turn * t,
      radius: lerpDouble(begin.radius, end.radius, t)!,
    );
  }

  @override
  void didUpdateWidget(AnimatedLiquidGlassCluster oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targets = _targets();
    if (!mapEquals(targets, _to) || widget.blendRadius != _toBlend) {
      final t = _progress;
      _from = {for (final id in _to.keys) id: _sample(id, t)};
      _fromBlend = lerpDouble(_fromBlend, _toBlend, t)!;
      _to = targets;
      _toBlend = widget.blendRadius;
      _curve = widget.curve;
      _controller.duration = widget.duration;
      if (_quiet || widget.duration == Duration.zero) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    } else if (_quiet || widget.duration == Duration.zero) {
      _controller.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quiet) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _progress;
          return LiquidGlassCluster(
            blendRadius: lerpDouble(_fromBlend, _toBlend, t)!,
            config: widget.config,
            accessibility: widget.accessibility,
            lightingController: widget.lightingController,
            onRenderPathChanged: widget.onRenderPathChanged,
            members: [
              for (final member in widget.members) _member(member, t),
            ],
          );
        },
      );

  LiquidGlassMember _member(LiquidGlassMember target, double t) {
    final sample = _sample(target.id, t);
    return LiquidGlassMember(
      id: target.id,
      bounds: sample.bounds,
      rotation: sample.angle,
      borderRadius: sample.radius,
      child: target.child,
    );
  }
}
