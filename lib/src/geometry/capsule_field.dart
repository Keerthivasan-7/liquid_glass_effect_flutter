import 'dart:ui';

import 'liquid_glass_shape.dart';

/// Internal geometry for the single-pass capture renderer. Coordinates are
/// local to its padded paint box. Foreground and fallback use individual paths.
class CapsuleField extends LiquidGlassShape {
  const CapsuleField(this.members, this.blendRadius) : super.capsule();

  final List<Rect> members;
  final double blendRadius;

  @override
  Path pathFor(Size size) {
    final path = Path();
    for (final rect in members) {
      path.addRRect(RRect.fromRectAndRadius(
          rect, Radius.circular(rect.shortestSide / 2)));
    }
    return path;
  }

  Rect member(int index) => index < members.length ? members[index] : Rect.zero;
}
