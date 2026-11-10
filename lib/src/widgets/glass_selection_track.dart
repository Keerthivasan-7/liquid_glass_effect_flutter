import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Keeps the foreground stationary while the two ends of the selected pill
/// travel at different speeds. Flutter retargets from the current rectangle.
class GlassSelectionTrack extends StatelessWidget {
  const GlassSelectionTrack(
      {required this.index,
      required this.children,
      required this.color,
      required this.quiet,
      required this.radius,
      super.key});
  final int index;
  final List<Widget> children;
  final Color color;
  final bool quiet;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final slot = rtl ? children.length - index - 1 : index;
    final bounds =
        Rect.fromLTWH(slot / children.length, 0, 1 / children.length, 1);
    return Material(
        type: MaterialType.transparency,
        child: Stack(children: [
          Positioned.fill(
              child: IgnorePointer(
                  child: TweenAnimationBuilder<Rect>(
            tween: _StretchTween(bounds),
            duration: quiet ? Duration.zero : const Duration(milliseconds: 320),
            builder: (context, rect, child) =>
                CustomPaint(painter: _Indicator(rect, color, radius)),
          ))),
          Row(children: [for (final child in children) Expanded(child: child)]),
        ]));
  }
}

class _StretchTween extends Tween<Rect> {
  _StretchTween(Rect target) : super(begin: target, end: target);

  @override
  Rect lerp(double t) {
    final forward = end!.center.dx >= begin!.center.dx;
    final leading = Curves.easeOutCubic.transform(t);
    final trailing = Curves.easeInOut.transform(t);
    return Rect.fromLTRB(
      lerpDouble(begin!.left, end!.left, forward ? trailing : leading)!,
      0,
      lerpDouble(begin!.right, end!.right, forward ? leading : trailing)!,
      1,
    );
  }
}

class _Indicator extends CustomPainter {
  const _Indicator(this.bounds, this.color, this.radius);
  final Rect bounds;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
        size.width * bounds.left, 0, size.width * bounds.right, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Indicator old) =>
      old.bounds != bounds || old.color != color || old.radius != radius;
}
