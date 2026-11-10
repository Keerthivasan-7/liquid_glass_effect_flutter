import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A tactile, interactive liquid glass button featuring fluid wave ripples,
/// specular sheen dynamics, and spring scale bounce.
class LiquidGlassButton extends StatelessWidget {
  /// Creates a tactile liquid glass button.
  const LiquidGlassButton({
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.borderRadius = 18.0,
    this.cornerSmoothing = 0.72,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.enableHaptics = true,
    this.semanticLabel,
    this.foregroundColor,
    this.lightingController,
    super.key,
  });

  /// Widget content inside the button (e.g. [Text], [Row], or [Icon]).
  final Widget child;

  /// Called when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Internal padding around the child. Defaults to 24x14.
  final EdgeInsetsGeometry padding;

  /// Corner radius of the button. Defaults to 18.0.
  final double borderRadius;

  /// Squircle corner smoothing. Defaults to 0.72.
  final double cornerSmoothing;

  /// Custom optical configuration. Defaults to [LiquidGlassConfig.crystal] for high clarity.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Whether to trigger subtle haptic impact on tap. Defaults to true.
  final bool enableHaptics;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Explicit foreground text and icon color. If null, adapts to [Theme.of(context)].
  final Color? foregroundColor;

  /// Optional lighting controller to synchronize dynamic specular highlights with device tilt or cursor.
  final ValueListenable<Offset>? lightingController;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final shape = LiquidGlassShape.roundedRectangle(borderRadius: borderRadius);
    return MergeSemantics(
        child: LiquidGlass(
      config: (config ?? const LiquidGlassConfig.crystal()).copyWith(
        cornerSmoothing: cornerSmoothing,
        refractionStrength: enabled ? null : 0.015,
        fresnelStrength: enabled ? null : 0.35,
      ),
      accessibility: accessibility,
      interactive: enabled,
      lightingController: lightingController,
      shape: shape,
      child: Builder(builder: (context) {
        final inherited = DefaultTextStyle.of(context).style.color ??
            Theme.of(context).colorScheme.onSurface;
        return TextButton(
          onPressed: enabled
              ? () {
                  if (enableHaptics) HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          style: TextButton.styleFrom(
            enableFeedback: false,
            foregroundColor: foregroundColor ?? inherited,
            disabledForegroundColor:
                (foregroundColor ?? inherited).withValues(alpha: 0.65),
            padding: padding,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius)),
          ),
          child: semanticLabel == null
              ? child
              : Semantics(
                  label: semanticLabel,
                  excludeSemantics: true,
                  child: child,
                ),
        );
      }),
    ));
  }
}
