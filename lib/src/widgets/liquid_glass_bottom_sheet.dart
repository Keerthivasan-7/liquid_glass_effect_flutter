import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A modal bottom sheet featuring frosted liquid glass, high-contrast readability,
/// and an integrated drag handle.
class LiquidGlassBottomSheet extends StatelessWidget {
  /// Creates a liquid glass bottom sheet container.
  const LiquidGlassBottomSheet({
    required this.child,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 28.0,
    this.showHandle = true,
    this.handleColor,
    this.padding = const EdgeInsets.all(20.0),
    this.lightingController,
    super.key,
  });

  /// The widget content inside the sheet.
  final Widget child;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Top corners radius. Defaults to 28.0.
  final double borderRadius;

  /// Whether to display a pill drag handle at the top. Defaults to true.
  final bool showHandle;

  /// Color of the grab handle pill. Defaults to semi-transparent foreground.
  final Color? handleColor;

  /// Padding around the content. Defaults to 20.0.
  final EdgeInsetsGeometry padding;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Displays a modal bottom sheet wrapped with [LiquidGlassBottomSheet].
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    LiquidGlassConfig? config,
    LiquidGlassAccessibilityPolicy accessibility =
        const LiquidGlassAccessibilityPolicy(),
    double borderRadius = 28.0,
    bool showHandle = true,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.45),
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (sheetContext) => LiquidGlassBottomSheet(
        config: config,
        accessibility: accessibility,
        borderRadius: borderRadius,
        showHandle: showHandle,
        child: builder(sheetContext),
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
      blurSigma: 16.0,
      roughness: 0.48,
      tint: isDark
          ? const Color(0x60060914)
          : const Color(0x35FFFFFF),
      absorptionColor: isDark
          ? const Color(0xFF070B16)
          : Colors.white,
      absorptionStrength: isDark ? 0.6 : 0.35,
    );

    final ink = DefaultTextStyle.of(context).style.color ??
        theme.colorScheme.onSurface;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: LiquidGlass(
        config: effectiveConfig,
        accessibility: accessibility,
        lightingController: lightingController,
        shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showHandle)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                    child: Container(
                      width: 38.0,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: handleColor ?? ink.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(2.25),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
