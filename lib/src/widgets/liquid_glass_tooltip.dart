// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A tooltip that wraps its message inside a high-contrast dark liquid glass capsule.
class LiquidGlassTooltip extends StatelessWidget {
  /// Creates a liquid glass tooltip.
  const LiquidGlassTooltip({
    required this.message,
    required this.child,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
    super.key,
  });

  /// The text message displayed inside the tooltip bubble.
  final String message;

  /// The widget that triggers the tooltip on hover or long press.
  final Widget child;

  /// Custom optical material configuration. Defaults to high-density dark glass.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Corner radius of the tooltip bubble. Defaults to 10.0.
  final double borderRadius;

  /// Internal padding around the message. Defaults to 10x6.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = (config ?? const LiquidGlassConfig.regular()).copyWith(
      blurSigma: 12.0,
      specularStrength: 0.85,
      fresnelStrength: 0.70,
      tint: const Color(0xB8090E1A),
      absorptionColor: const Color(0xFF030712),
      absorptionStrength: 0.85,
      edgeWidth: 0.05,
    );

    return Tooltip(
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.transparent),
      richMessage: WidgetSpan(
        child: LiquidGlass(
          config: effectiveConfig,
          accessibility: accessibility,
          shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
          padding: padding,
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
