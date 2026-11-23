import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A compact, interactive liquid glass chip for filters, tags, and selections.
class LiquidGlassChip extends StatelessWidget {
  /// Creates an interactive liquid glass chip.
  const LiquidGlassChip({
    required this.label,
    this.avatar,
    this.deleteIcon,
    this.onSelected,
    this.onDeleted,
    this.selected = false,
    this.selectedColor,
    this.borderRadius = 18.0,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
    super.key,
  });

  /// Primary label widget.
  final Widget label;

  /// Optional leading icon or avatar.
  final Widget? avatar;

  /// Optional trailing delete icon.
  final Widget? deleteIcon;

  /// Called when the chip is tapped.
  final ValueChanged<bool>? onSelected;

  /// Called when the delete icon is pressed.
  final VoidCallback? onDeleted;

  /// Whether the chip is actively selected.
  final bool selected;

  /// Accent color applied when [selected] is true.
  final Color? selectedColor;

  /// Corner radius of the chip pill. Defaults to 18.0.
  final double borderRadius;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Internal padding. Defaults to 12 horizontal by 7 vertical.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final effectiveConfig = (config ??
            glassTheme.defaultConfig ??
            const LiquidGlassConfig.regular())
        .copyWith(
      tint: selected
          ? (selectedColor ?? theme.colorScheme.primary).withValues(alpha: 0.32)
          : null,
      specularStrength: selected ? 0.8 : null,
      fresnelStrength: selected ? 0.75 : null,
    );

    final ink =
        DefaultTextStyle.of(context).style.color ?? theme.colorScheme.onSurface;

    return Semantics(
      selected: selected,
      button: onSelected != null,
      child: GestureDetector(
        onTap: onSelected != null ? () => onSelected!(!selected) : null,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlass(
          config: effectiveConfig,
          accessibility: accessibility,
          lightingController: lightingController,
          shape: LiquidGlassShape.roundedRectangle(borderRadius: borderRadius),
          interactive: onSelected != null,
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (avatar != null) ...<Widget>[
                avatar!,
                const SizedBox(width: 6.0),
              ],
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? (selectedColor ?? theme.colorScheme.primary)
                      : ink,
                ),
                child: label,
              ),
              if (onDeleted != null) ...<Widget>[
                const SizedBox(width: 4.0),
                GestureDetector(
                  onTap: onDeleted,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: deleteIcon ??
                        Icon(
                          Icons.cancel,
                          size: 16.0,
                          color: ink.withValues(alpha: 0.65),
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
