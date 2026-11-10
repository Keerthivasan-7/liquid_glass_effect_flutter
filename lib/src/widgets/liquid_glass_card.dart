import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A padded glass surface with a continuous rounded outline.
class LiquidGlassCard extends StatelessWidget {
  /// Creates an elevated liquid glass card.
  const LiquidGlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.cornerSmoothing = 0.72,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.interactive = false,
    super.key,
  });

  /// The widget content displayed inside the card.
  final Widget child;

  /// Internal padding around [child]. Defaults to 20 logical pixels.
  final EdgeInsetsGeometry padding;

  /// Empty space surrounding the card.
  final EdgeInsetsGeometry? margin;

  /// Optional fixed width for the card.
  final double? width;

  /// Optional fixed height for the card.
  final double? height;

  /// Corner radius of the card's squircle boundary. Defaults to 24.0.
  final double borderRadius;

  /// Corner squircle smoothing exponent (0.0 = classic rounded rect, 1.0 = iOS squircle).
  final double cornerSmoothing;

  /// Custom optical material configuration. Defaults to [LiquidGlassConfig.regular].
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Optional lighting controller to synchronize dynamic specular highlights with device tilt or cursor.
  final ValueListenable<Offset>? lightingController;

  /// Whether the card provides subtle fluid motion feedback on hover and press.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig =
        (config ?? const LiquidGlassConfig.regular()).copyWith(
      cornerSmoothing: cornerSmoothing,
    );

    Widget surface = LiquidGlass(
      config: effectiveConfig,
      accessibility: accessibility,
      interactive: interactive,
      lightingController: lightingController,
      shape: LiquidGlassShape.roundedRectangle(
        borderRadius: borderRadius,
      ),
      padding: padding,
      width: width,
      height: height,
      child: child,
    );

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}
