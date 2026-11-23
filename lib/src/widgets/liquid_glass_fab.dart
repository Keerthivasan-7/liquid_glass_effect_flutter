import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A floating action button featuring crystal liquid glass, fluid wave ripples on tap,
/// and ambient elevation shadows.
class LiquidGlassFAB extends StatelessWidget {
  /// Creates a circular or rounded liquid glass floating action button.
  const LiquidGlassFAB({
    required this.child,
    required this.onPressed,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.size = 56.0,
    this.enableHaptics = true,
    this.semanticLabel,
    this.foregroundColor,
    this.lightingController,
    super.key,
  })  : isExtended = false,
        label = null,
        icon = null;

  /// Creates an extended liquid glass floating action button with icon and label.
  const LiquidGlassFAB.extended({
    required this.label,
    required this.onPressed,
    this.icon,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.enableHaptics = true,
    this.semanticLabel,
    this.foregroundColor,
    this.lightingController,
    super.key,
  })  : isExtended = true,
        size = 56.0,
        child = null;

  /// Content widget for standard FAB (typically an [Icon]).
  final Widget? child;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// Custom optical material configuration. Defaults to [LiquidGlassConfig.crystal].
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Diameter of the button when standard. Defaults to 56.0.
  final double size;

  /// Whether to produce haptic impact on press. Defaults to true.
  final bool enableHaptics;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Explicit color for icons and text.
  final Color? foregroundColor;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Whether this is an extended FAB pill.
  final bool isExtended;

  /// Primary label widget for extended FAB.
  final Widget? label;

  /// Optional leading icon for extended FAB.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final enabled = onPressed != null;

    final effectiveConfig = (config ??
            glassTheme.buttonConfig ??
            glassTheme.defaultConfig ??
            const LiquidGlassConfig.crystal())
        .copyWith(
      fresnelStrength: enabled ? 0.95 : 0.4,
      specularStrength: enabled ? 0.90 : 0.35,
    );

    final ink = foregroundColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white
            : theme.colorScheme.primary);

    Widget content;
    if (isExtended) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              IconTheme.merge(
                data: IconThemeData(color: ink, size: 22.0),
                child: icon!,
              ),
              const SizedBox(width: 8.0),
            ],
            DefaultTextStyle.merge(
              style: TextStyle(
                color: ink,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
              child: label!,
            ),
          ],
        ),
      );
    } else {
      content = IconTheme.merge(
        data: IconThemeData(color: ink, size: 24.0),
        child: child!,
      );
    }

    final shape = isExtended
        ? const LiquidGlassShape.capsule()
        : const LiquidGlassShape.circle();

    return Container(
      decoration: BoxDecoration(
        shape: isExtended ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isExtended ? BorderRadius.circular(size / 2) : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: semanticLabel,
        enabled: enabled,
        child: LiquidGlass(
          config: effectiveConfig,
          accessibility: accessibility,
          lightingController: lightingController,
          shape: shape,
          interactive: enabled,
          width: isExtended ? null : size,
          height: size,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled
                  ? () {
                      if (enableHaptics) HapticFeedback.lightImpact();
                      onPressed!();
                    }
                  : null,
              customBorder:
                  isExtended ? const StadiumBorder() : const CircleBorder(),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
