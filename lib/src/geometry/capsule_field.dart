import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'liquid_glass_shape.dart';

/// A capsule is a line segment swept by a disk. Its half-spine encodes
/// orientation and length in the cluster's coordinate system.
class PlacedCapsule {
  PlacedCapsule(this.bounds, this.rotation)
      : spine = Offset.fromDirection(
          rotation + (bounds.height > bounds.width ? math.pi / 2 : 0),
          (bounds.width - bounds.height).abs() / 2,
        );

  PlacedCapsule._(this.bounds, this.rotation, this.spine);
  final Rect bounds;
  final double rotation;
  final Offset spine;
  Offset get center => bounds.center;
  double get radius => bounds.shortestSide / 2;
  Rect get extent =>
      Rect.fromPoints(center - spine, center + spine).inflate(radius);
  PlacedCapsule shift(Offset offset) =>
      PlacedCapsule._(bounds.shift(offset), rotation, spine);

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
