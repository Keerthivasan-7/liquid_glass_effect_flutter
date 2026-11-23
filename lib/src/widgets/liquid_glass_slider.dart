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

/// A fluid, tactile range slider featuring liquid glass track and thumb
/// with real-time refraction and haptic ticks.
class LiquidGlassSlider extends StatefulWidget {
  /// Creates a liquid glass range slider.
  const LiquidGlassSlider({
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.enableHaptics = true,
    this.lightingController,
    this.height = 36.0,
    super.key,
  })  : assert(min < max),
        assert(value >= min && value <= max),
        assert(divisions == null || divisions > 0);

  /// Current value of the slider between [min] and [max].
  final double value;

  /// Called when the value changes during drag or tap.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts dragging.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user finishes dragging.
  final ValueChanged<double>? onChangeEnd;

  /// Minimum value. Defaults to 0.0.
  final double min;

  /// Maximum value. Defaults to 1.0.
  final double max;

  /// Number of discrete intervals. If null, continuous dragging is used.
  final int? divisions;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Color for the filled active track. Defaults to theme primary accent.
  final Color? activeColor;

  /// Color for the unfilled track. Defaults to subtle translucent grey.
  final Color? inactiveColor;

  /// Color for the glass thumb.
  final Color? thumbColor;

  /// Whether to produce haptic feedback when dragging past discrete divisions.
  final bool enableHaptics;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Total height of the interactive touch region. Defaults to 36.0.
  final double height;

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider> {
  bool _isDragging = false;
  int? _lastDivisionIndex;

  bool get _enabled => widget.onChanged != null;

  double get _fraction =>
      ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  void _handleDrag(Offset localPosition, double width) {
    if (!_enabled || width <= 0) return;
    final thumbRadius = widget.height * 0.35;
    final availableWidth = width - thumbRadius * 2;
    if (availableWidth <= 0) return;

    var newFraction =
        ((localPosition.dx - thumbRadius) / availableWidth).clamp(0.0, 1.0);

    if (widget.divisions != null) {
      final divCount = widget.divisions!;
      final rawDivision = (newFraction * divCount).round();
      newFraction = rawDivision / divCount;

      if (widget.enableHaptics && rawDivision != _lastDivisionIndex) {
        _lastDivisionIndex = rawDivision;
        HapticFeedback.selectionClick();
      }
    }

    final newValue = widget.min + newFraction * (widget.max - widget.min);
    if (newValue != widget.value) {
      widget.onChanged!(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final effectiveConfig = widget.config ??
        glassTheme.inputConfig ??
        glassTheme.defaultConfig ??
        const LiquidGlassConfig.frosted();

    final active = widget.activeColor ?? theme.colorScheme.primary;
    final inactive = widget.inactiveColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0x20FFFFFF)
            : const Color(0x14000000));

    final railHeight = 8.0;
    final thumbDiameter = 24.0;

    return Semantics(
      slider: true,
      value: widget.value.toStringAsFixed(1),
      enabled: _enabled,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fraction = _fraction;
          final thumbX = fraction * (width - thumbDiameter);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (details) {
              if (!_enabled) return;
              setState(() => _isDragging = true);
              widget.onChangeStart?.call(widget.value);
              _handleDrag(details.localPosition, width);
            },
            onHorizontalDragUpdate: (details) {
              _handleDrag(details.localPosition, width);
            },
            onHorizontalDragEnd: (details) {
              if (!_enabled) return;
              setState(() => _isDragging = false);
              widget.onChangeEnd?.call(widget.value);
            },
            onTapDown: (details) {
              if (!_enabled) return;
              _handleDrag(details.localPosition, width);
            },
            child: SizedBox(
              width: width,
              height: widget.height,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  // Background rail
                  Positioned(
                    left: 0,
                    right: 0,
                    height: railHeight,
                    child: LiquidGlass(
                      config: effectiveConfig.copyWith(
                        tint: inactive,
                        blurSigma: 6.0,
                      ),
                      accessibility: widget.accessibility,
                      shape: const LiquidGlassShape.capsule(),
                      child: Stack(
                        children: <Widget>[
                          // Active filled progress
                          FractionallySizedBox(
                            widthFactor: fraction,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: active.withValues(alpha: 0.72),
                                borderRadius:
                                    BorderRadius.circular(railHeight / 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Refractive thumb orb
                  Positioned(
                    left: thumbX,
                    child: AnimatedScale(
                      scale: _isDragging ? 1.18 : 1.0,
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutBack,
                      child: LiquidGlass(
                        config: const LiquidGlassConfig.crystal().copyWith(
                          blurSigma: 1.0,
                          specularStrength: 1.1,
                          fresnelStrength: 0.9,
                        ),
                        accessibility: widget.accessibility,
                        lightingController: widget.lightingController,
                        shape: const LiquidGlassShape.circle(),
                        width: thumbDiameter,
                        height: thumbDiameter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.thumbColor ??
                                Colors.white.withValues(alpha: 0.9),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 6.0,
                                offset: const Offset(0, 2),
                              ),
                              if (_isDragging)
                                BoxShadow(
                                  color: active.withValues(alpha: 0.4),
                                  blurRadius: 10.0,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
