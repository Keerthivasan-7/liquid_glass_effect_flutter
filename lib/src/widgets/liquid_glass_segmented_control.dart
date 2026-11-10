import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/liquid_glass_shape.dart';
import 'glass_selection_track.dart';
import 'liquid_glass.dart';

/// A single-selection glass control. Each segment keeps its own focus and
/// activation target while the indicator stretches between selection changes.
class LiquidGlassSegmentedControl<T extends Object> extends StatelessWidget {
  const LiquidGlassSegmentedControl(
      {required this.segments,
      required this.selected,
      required this.onSelected,
      this.config = const LiquidGlassConfig.regular(),
      this.accessibility = const LiquidGlassAccessibilityPolicy(),
      super.key});

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onSelected;
  final LiquidGlassConfig config;
  final LiquidGlassAccessibilityPolicy accessibility;

  @override
  Widget build(BuildContext context) {
    final index = segments.indexWhere((s) => s.value == selected);
    if (segments.length < 2 ||
        index < 0 ||
        segments.map((s) => s.value).toSet().length != segments.length) {
      throw ArgumentError(
          'Provide at least two distinct segments and select one of them.');
    }
    final media = MediaQuery.maybeOf(context);
    return LiquidGlass(
        config: config,
        accessibility: accessibility,
        shape: const LiquidGlassShape.roundedRectangle(borderRadius: 20),
        padding: const EdgeInsets.all(3),
        child: Builder(builder: (context) {
          final ink = DefaultTextStyle.of(context).style.color ??
              Theme.of(context).colorScheme.onSurface;
          return GlassSelectionTrack(
              index: index,
              color: ink.withValues(alpha: .12),
              radius: 18,
              quiet: accessibility.reduceMotion ||
                  (media?.disableAnimations ?? false) ||
                  (media?.accessibleNavigation ?? false),
              children: [
                for (final segment in segments)
                  Semantics(
                    selected: segment.value == selected,
                    inMutuallyExclusiveGroup: true,
                    child: Tooltip(
                      message: segment.tooltip ?? '',
                      excludeFromSemantics: segment.label != null,
                      child: TextButton(
                        onPressed: onSelected != null && segment.enabled
                            ? () => onSelected!(segment.value)
                            : null,
                        style: TextButton.styleFrom(
                            foregroundColor: ink,
                            minimumSize: const Size(48, 48)),
                        child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              if (segment.icon != null) segment.icon!,
                              if (segment.label != null) segment.label!
                            ]),
                      ),
                    ),
                  ),
              ]);
        }));
  }
}
