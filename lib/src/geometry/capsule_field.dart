import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'liquid_glass_shape.dart';

/// A rounded rectangle placed in the cluster coordinate system.
class PlacedCapsule {
  PlacedCapsule(this.bounds, this.rotation, {double? borderRadius})
      : radius = (borderRadius ?? bounds.shortestSide / 2)
            .clamp(0, bounds.shortestSide / 2);

  PlacedCapsule._(this.bounds, this.rotation, this.radius);
  final Rect bounds;
  final double rotation;
  Offset get center => bounds.center;
  final double radius;
  Rect get extent => Rect.fromCenter(
      center: center,
      width: 2 *
          ((bounds.width / 2 - radius) * math.cos(rotation).abs() +
              (bounds.height / 2 - radius) * math.sin(rotation).abs() +
              radius),
      height: 2 *
          ((bounds.width / 2 - radius) * math.sin(rotation).abs() +
              (bounds.height / 2 - radius) * math.cos(rotation).abs() +
              radius));
  PlacedCapsule shift(Offset offset) =>
      PlacedCapsule._(bounds.shift(offset), rotation, radius);

  void addTo(Path path) {
    final rounded = RRect.fromRectAndRadius(bounds, Radius.circular(radius));
    if (rotation == 0) {
      path.addRRect(rounded);
      return;
    }
    final local = Path()..addRRect(rounded.shift(-center));
    final transform = Matrix4.translationValues(center.dx, center.dy, 0)
      ..rotateZ(rotation);
    path.addPath(local, Offset.zero, matrix4: transform.storage);
  }
}

/// Internal geometry for the single-pass capture renderer. Coordinates are
/// local to its padded paint box. Foreground and fallback use individual paths.
class CapsuleField extends LiquidGlassShape {
  const CapsuleField(this.members, this.blendRadius) : super.capsule();

  final List<PlacedCapsule> members;
  final double blendRadius;

  @override
  Path pathFor(Size size) {
    final path = Path();
    for (final member in members) {
      member.addTo(path);
    }
    return path;
  }

  PlacedCapsule? member(int index) =>
      index < members.length ? members[index] : null;
}
