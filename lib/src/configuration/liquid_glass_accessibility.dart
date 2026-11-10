import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// App-controlled accessibility preferences for one glass surface.
///
/// Reduced transparency is explicit because Flutter does not expose the same
/// system preference consistently on every platform. High contrast is read
/// from MediaQuery unless overridden. Either preference selects an opaque
/// fallback surface without shaders, captures, or backdrop blur.
@immutable
class LiquidGlassAccessibilityPolicy {
  const LiquidGlassAccessibilityPolicy({
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.highContrast,
    this.opaqueColor,
  });

  final bool reduceTransparency;

  /// Forces reduced motion in addition to MediaQuery's motion signals.
  final bool reduceMotion;

  /// Null follows MediaQuery; false lets an app manage contrast itself.
  final bool? highContrast;

  /// Opaque treatment color; defaults to the theme's surface color.
  /// Its alpha is always made fully opaque.
  final Color? opaqueColor;

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassAccessibilityPolicy &&
      other.reduceTransparency == reduceTransparency &&
      other.reduceMotion == reduceMotion &&
      other.highContrast == highContrast &&
      other.opaqueColor == opaqueColor;

  @override
  int get hashCode =>
      Object.hash(reduceTransparency, reduceMotion, highContrast, opaqueColor);
}
