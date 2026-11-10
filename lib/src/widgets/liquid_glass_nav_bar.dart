import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';
import 'glass_selection_track.dart';

/// An item descriptor for a [LiquidGlassNavBar].
class LiquidGlassNavItem {
  /// Creates a navigation bar item.
  const LiquidGlassNavItem({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.tooltip,
  });

  /// The icon widget shown when unselected.
  final Widget icon;

  /// Optional icon widget shown when selected.
  final Widget? selectedIcon;

  /// Optional label text shown below or next to the icon.
  final String? label;

  /// Optional tooltip text.
  final String? tooltip;
}

/// A floating, fluid liquid glass navigation bar pill with animated selection gliding.
class LiquidGlassNavBar extends StatelessWidget {
  /// Creates a floating liquid glass navigation bar.
  const LiquidGlassNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 32.0,
    this.height = 68.0,
    this.activeIndicatorColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.lightingController,
    super.key,
  })  : assert(items.length >= 2,
            'LiquidGlassNavBar requires at least two items.'),
        assert(currentIndex >= 0 && currentIndex < items.length);

  /// The navigation destinations.
  final List<LiquidGlassNavItem> items;

  /// Index of the currently selected destination.
  final int currentIndex;

  /// Callback when a destination is tapped.
  final ValueChanged<int> onTap;

  /// Custom optical material configuration. Defaults to [LiquidGlassConfig.frosted].
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Outer corner radius. Defaults to 32.0 (pill shape).
  final double borderRadius;

  /// Height of the navigation bar. Defaults to 68.0.
  final double height;

  /// Color of the active selection indicator pill. If null, adapts to current theme.
  final Color? activeIndicatorColor;

  /// Foreground color of the selected item's icon and label.
  final Color? selectedItemColor;

  /// Foreground color of unselected items' icons and labels.
  final Color? unselectedItemColor;

  /// Outer padding inside the glass container.
  final EdgeInsetsGeometry padding;

  /// Optional lighting controller to synchronize dynamic specular highlights with device tilt or cursor.
  final ValueListenable<Offset>? lightingController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.maybeOf(context);
    final quiet = accessibility.reduceMotion ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    final opaque = accessibility.reduceTransparency ||
        (accessibility.highContrast ?? media?.highContrast ?? false);
    return LiquidGlass(
      config: (config ?? const LiquidGlassConfig.frosted())
          .copyWith(cornerSmoothing: 0.82),
      accessibility: accessibility,
      lightingController: lightingController,
      shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: padding,
          child: Builder(builder: (context) {
            final ink = DefaultTextStyle.of(context).style.color ??
                theme.colorScheme.onSurface;
            return GlassSelectionTrack(
                index: currentIndex,
                color: activeIndicatorColor ?? ink.withValues(alpha: .12),
                quiet: quiet,
                radius: borderRadius,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Semantics(
                      selected: i == currentIndex,
                      button: true,
                      child: Tooltip(
                        message: items[i].tooltip ?? items[i].label ?? '',
                        excludeFromSemantics: items[i].label != null,
                        child: InkWell(
                          onTap: () => onTap(i),
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconTheme.merge(
                                      data: IconThemeData(
                                          size: 22,
                                          color: i == currentIndex
                                              ? selectedItemColor ?? ink
                                              : unselectedItemColor ??
                                                  ink.withValues(
                                                      alpha: opaque ? 1 : .8)),
                                      child: i == currentIndex
                                          ? items[i].selectedIcon ??
                                              items[i].icon
                                          : items[i].icon),
                                  if (items[i].label != null)
                                    Text(items[i].label!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: i == currentIndex
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: i == currentIndex
                                                ? selectedItemColor ?? ink
                                                : unselectedItemColor ?? ink)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]);
          }),
        ),
      ),
    );
  }
}
