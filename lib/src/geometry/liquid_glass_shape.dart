import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Geometry understood by both the Flutter clipper and the optical shader.
enum LiquidGlassShapeKind { roundedRectangle, capsule, circle }

/// Immutable geometry for a liquid glass surface.
@immutable
class LiquidGlassShape {
  const LiquidGlassShape.roundedRectangle({this.borderRadius = 28})
      : kind = LiquidGlassShapeKind.roundedRectangle,
        assert(borderRadius >= 0);

  const LiquidGlassShape.capsule()
      : kind = LiquidGlassShapeKind.capsule,
        borderRadius = 0;

  const LiquidGlassShape.circle()
      : kind = LiquidGlassShapeKind.circle,
        borderRadius = 0;

  final LiquidGlassShapeKind kind;
  final double borderRadius;

  /// Radius used by the rounded-distance field for [size].
  double resolvedRadius(Size size) {
    final halfShortest = math.min(size.width, size.height) / 2;
    return switch (kind) {
      LiquidGlassShapeKind.roundedRectangle => borderRadius.clamp(
          0.0,
          halfShortest,
        ),
      LiquidGlassShapeKind.capsule ||
      LiquidGlassShapeKind.circle =>
        halfShortest,
    };
  }

  /// Produces the exact path used for clipping and decoration.
  Path pathFor(Size size) {
    final rect = Offset.zero & size;
    return switch (kind) {
      LiquidGlassShapeKind.circle => Path()..addOval(rect),
      LiquidGlassShapeKind.capsule ||
      LiquidGlassShapeKind.roundedRectangle =>
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
                rect, Radius.circular(resolvedRadius(size))),
          ),
    };
  }

  /// Numeric shape identifier shared with the shader.
  double get shaderValue => switch (kind) {
        LiquidGlassShapeKind.roundedRectangle => 0,
        LiquidGlassShapeKind.capsule => 1,
        LiquidGlassShapeKind.circle => 2,
      };
}
