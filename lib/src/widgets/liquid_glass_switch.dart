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

/// A tactile, liquid glass toggle switch featuring fluid refraction,
/// smooth spring physics, and haptic feedback.
class LiquidGlassSwitch extends StatefulWidget {
  /// Creates a liquid glass toggle switch.
  const LiquidGlassSwitch({
    required this.value,
    required this.onChanged,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.enableHaptics = true,
    this.lightingController,
    this.semanticLabel,
    this.width = 54.0,
    this.height = 32.0,
    super.key,
  })  : assert(width >= 40.0),
        assert(height >= 24.0);

  /// Whether this switch is turned on.
  final bool value;

  /// Called when the user toggles the switch. If null, the switch is disabled.
  final ValueChanged<bool>? onChanged;

  /// Custom optical material configuration for the track.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Background tint for the track when active. Defaults to theme accent.
  final Color? activeTrackColor;

  /// Background tint for the track when inactive. Defaults to subtle grey/white.
  final Color? inactiveTrackColor;

  /// Foreground color of the switch thumb.
  final Color? thumbColor;

  /// Whether to produce subtle haptic impact on toggle. Defaults to true.
  final bool enableHaptics;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Total width of the switch track. Defaults to 54.0.
  final double width;

  /// Total height of the switch track. Defaults to 32.0.
  final double height;

  @override
  State<LiquidGlassSwitch> createState() => _LiquidGlassSwitchState();
}

class _LiquidGlassSwitchState extends State<LiquidGlassSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _thumbPosition;

  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.value ? 1.0 : 0.0,
    );
    _thumbPosition = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_enabled) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final effectiveConfig = widget.config ??
        glassTheme.inputConfig ??
        glassTheme.defaultConfig ??
        const LiquidGlassConfig.frosted();

    final activeColor = widget.activeTrackColor ??
        theme.colorScheme.primary.withValues(alpha: 0.35);
    final inactiveColor = widget.inactiveTrackColor ??
        (theme.brightness == Brightness.dark
            ? const Color(0x20FFFFFF)
            : const Color(0x14000000));

    final thumbDiameter = widget.height - 6.0;
    final travelDistance = widget.width - thumbDiameter - 6.0;

    return Semantics(
      label: widget.semanticLabel,
      toggled: widget.value,
      enabled: _enabled,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _thumbPosition,
            builder: (context, _) {
              final t = _thumbPosition.value;
              final trackTint =
                  Color.lerp(inactiveColor, activeColor, t.clamp(0.0, 1.0))!;

              return LiquidGlass(
                config: effectiveConfig.copyWith(tint: trackTint),
                accessibility: widget.accessibility,
                lightingController: widget.lightingController,
                shape: const LiquidGlassShape.capsule(),
                interactive: _enabled,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      Transform.translate(
                        offset: Offset(t * travelDistance, 0),
                        child: LiquidGlass(
                          config: const LiquidGlassConfig.crystal().copyWith(
                            blurSigma: 1.0,
                            specularStrength: 0.95,
                            fresnelStrength: 0.85,
                          ),
                          accessibility: widget.accessibility,
                          shape: const LiquidGlassShape.circle(),
                          width: thumbDiameter,
                          height: thumbDiameter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.thumbColor ??
                                  Colors.white.withValues(alpha: 0.92),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 4.0,
                                  offset: Offset(0, 1.5),
                                ),
                              ],
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
        ),
      ),
    );
  }
}
