import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// An item descriptor for [LiquidGlassDropdown].
class LiquidGlassDropdownItem<T> {
  /// Creates a dropdown item.
  const LiquidGlassDropdownItem({
    required this.value,
    required this.child,
    this.enabled = true,
  });

  /// The data value represented by this item.
  final T value;

  /// The widget content displayed for this item.
  final Widget child;

  /// Whether the user can select this item.
  final bool enabled;
}

/// A select dropdown menu featuring frosted liquid glass container styling.
class LiquidGlassDropdown<T> extends StatelessWidget {
  /// Creates a liquid glass dropdown selector.
  const LiquidGlassDropdown({
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 16.0,
    this.lightingController,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    super.key,
  });

  /// The list of selectable items.
  final List<LiquidGlassDropdownItem<T>> items;

  /// Called when the user selects an item.
  final ValueChanged<T?>? onChanged;

  /// Currently selected value.
  final T? value;

  /// Placeholder hint widget shown when [value] is null.
  final Widget? hint;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Corner radius of the dropdown container. Defaults to 16.0.
  final double borderRadius;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Internal padding. Defaults to 16 horizontal by 4 vertical.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final effectiveConfig = config ??
        glassTheme.inputConfig ??
        glassTheme.defaultConfig ??
        const LiquidGlassConfig.frosted();

    final ink = DefaultTextStyle.of(context).style.color ??
        theme.colorScheme.onSurface;

    return LiquidGlass(
      config: effectiveConfig,
      accessibility: accessibility,
      lightingController: lightingController,
      shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
      padding: padding,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: ink),
          dropdownColor: theme.brightness == Brightness.dark
              ? const Color(0xFF131A2A)
              : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          items: <DropdownMenuItem<T>>[
            for (final item in items)
              DropdownMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                child: item.child,
              ),
          ],
        ),
      ),
    );
  }
}
