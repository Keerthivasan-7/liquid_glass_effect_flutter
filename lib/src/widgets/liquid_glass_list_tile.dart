import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A liquid glass list tile designed for settings, menus, and dashboard lists.
class LiquidGlassListTile extends StatelessWidget {
  /// Creates a liquid glass list tile.
  const LiquidGlassListTile({
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.selectedColor,
    this.borderRadius = 16.0,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    super.key,
  });

  /// Optional leading widget (e.g. [Icon] or avatar).
  final Widget? leading;

  /// Primary title widget.
  final Widget? title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Optional trailing widget (e.g. chevron or [Switch]).
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether this tile is highlighted as selected.
  final bool selected;

  /// Accent color applied when [selected] is true.
  final Color? selectedColor;

  /// Corner radius of the tile squircle. Defaults to 16.0.
  final double borderRadius;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Internal padding. Defaults to 16 horizontal by 12 vertical.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final isTappable = onTap != null;

    final effectiveConfig = (config ??
            glassTheme.cardConfig ??
            glassTheme.defaultConfig ??
            const LiquidGlassConfig.regular())
        .copyWith(
      tint: selected
          ? (selectedColor ?? theme.colorScheme.primary).withValues(alpha: 0.22)
          : null,
      specularStrength: selected ? 0.75 : null,
    );

    final ink =
        DefaultTextStyle.of(context).style.color ?? theme.colorScheme.onSurface;

    return Semantics(
      button: isTappable,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlass(
          config: effectiveConfig,
          accessibility: accessibility,
          lightingController: lightingController,
          shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
          interactive: isTappable,
          padding: padding,
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                IconTheme.merge(
                  data: IconThemeData(
                    color: selected
                        ? (selectedColor ?? theme.colorScheme.primary)
                        : ink,
                    size: 24.0,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 14.0),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (title != null)
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? (selectedColor ?? theme.colorScheme.primary)
                              : ink,
                        ),
                        child: title!,
                      ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 3.0),
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 13.0,
                          color: ink.withValues(alpha: 0.65),
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 12.0),
                IconTheme.merge(
                  data: IconThemeData(
                    color: ink.withValues(alpha: 0.5),
                    size: 20.0,
                  ),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
