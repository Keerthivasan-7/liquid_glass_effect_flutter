import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A modal dialog featuring frosted liquid glass and high-contrast content presentation.
class LiquidGlassDialog extends StatelessWidget {
  /// Creates a liquid glass modal dialog.
  const LiquidGlassDialog({
    this.title,
    this.content,
    this.actions,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 24.0,
    this.insetPadding = const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
    this.lightingController,
    super.key,
  });

  /// Optional dialog title widget.
  final Widget? title;

  /// Primary dialog content widget.
  final Widget? content;

  /// Optional list of action buttons displayed along the bottom.
  final List<Widget>? actions;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Corner radius of the dialog container. Defaults to 24.0.
  final double borderRadius;

  /// Empty space surrounding the dialog. Defaults to 40 horizontal by 24 vertical.
  final EdgeInsets insetPadding;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Displays a dialog wrapped with [LiquidGlassDialog].
  static Future<T?> show<T>({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
    LiquidGlassConfig? config,
    LiquidGlassAccessibilityPolicy accessibility =
        const LiquidGlassAccessibilityPolicy(),
    double borderRadius = 24.0,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => LiquidGlassDialog(
        title: title,
        content: content,
        actions: actions,
        config: config,
        accessibility: accessibility,
        borderRadius: borderRadius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveConfig = (config ??
            glassTheme.overlayConfig ??
            glassTheme.defaultConfig ??
            const LiquidGlassConfig.frosted())
        .copyWith(
      blurSigma: 18.0,
      roughness: 0.50,
      tint: isDark
          ? const Color(0x60070B16)
          : const Color(0x35FFFFFF),
      absorptionColor: isDark
          ? const Color(0xFF080D1A)
          : Colors.white,
      absorptionStrength: isDark ? 0.65 : 0.35,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: LiquidGlass(
        config: effectiveConfig,
        accessibility: accessibility,
        lightingController: lightingController,
        shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (title != null) ...<Widget>[
                DefaultTextStyle.merge(
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  child: title!,
                ),
                const SizedBox(height: 16.0),
              ],
              if (content != null) ...<Widget>[
                Flexible(
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium,
                    child: content!,
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
