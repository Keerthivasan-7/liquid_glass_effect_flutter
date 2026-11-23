import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A floating or pinned app bar with frosted liquid glass backdrop and crisp controls.
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a liquid glass app bar.
  const LiquidGlassAppBar({
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.height = kToolbarHeight,
    this.borderRadius = 0.0,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.foregroundColor,
    super.key,
  });

  /// Primary title widget.
  final Widget? title;

  /// Optional widget displayed before the title (e.g. back button or drawer toggle).
  final Widget? leading;

  /// Optional action widgets displayed after the title.
  final List<Widget>? actions;

  /// Optional widget displayed below the toolbar.
  final PreferredSizeWidget? bottom;

  /// Whether the title should be centered. Defaults to true.
  final bool centerTitle;

  /// Height of the toolbar portion. Defaults to [kToolbarHeight] (56.0).
  final double height;

  /// Bottom corners radius if floating. Defaults to 0 (flat flush edge).
  final double borderRadius;

  /// Custom optical material configuration. Defaults to [LiquidGlassConfig.frosted].
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Explicit color for icons and title text. Defaults to theme onSurface.
  final Color? foregroundColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final effectiveConfig = config ??
        glassTheme.navBarConfig ??
        glassTheme.defaultConfig ??
        const LiquidGlassConfig.frosted();

    final ink = foregroundColor ??
        DefaultTextStyle.of(context).style.color ??
        theme.colorScheme.onSurface;

    Widget appBar = AppBar(
      title: title,
      leading: leading,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
    );

    return LiquidGlass(
      config: effectiveConfig,
      accessibility: accessibility,
      lightingController: lightingController,
      shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
      child: appBar,
    );
  }
}
