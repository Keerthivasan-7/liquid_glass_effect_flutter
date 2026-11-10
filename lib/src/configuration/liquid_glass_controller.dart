import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reactive controller that dynamically drives optical lighting, specular
/// highlights, and tilt responses across [LiquidGlass] surfaces.
///
/// Can be fed by pointer position, gyroscope/accelerometer streams, or custom animations.
class LiquidGlassLightingController extends ValueNotifier<Offset> {
  /// Creates a lighting controller with an initial normalized light direction.
  LiquidGlassLightingController(
      [super.initialDirection = const Offset(-0.65, -0.75)]);

  /// Maps tilt in radians to a light vector. A level device points straight
  /// at the surface (zero lateral light); a quarter turn reaches full tilt.
  void updateFromTilt({required double pitch, required double roll}) {
    if (!pitch.isFinite || !roll.isFinite) return;
    value = _unitDisk(Offset(math.sin(roll), -math.sin(pitch)));
  }

  /// Maps the surface center to zero and each axis edge to full tilt.
  void updateFromPointer(Offset localPointer, Size surfaceSize) {
    if (!localPointer.isFinite ||
        !surfaceSize.isFinite ||
        surfaceSize.isEmpty) {
      return;
    }
    value = _unitDisk(Offset(
      (2 * (localPointer.dx / surfaceSize.width) - 1).clamp(-1, 1),
      (2 * (localPointer.dy / surfaceSize.height) - 1).clamp(-1, 1),
    ));
  }

  static Offset _unitDisk(Offset vector) =>
      vector.distanceSquared > 1 ? vector / vector.distance : vector;
}
