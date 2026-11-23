// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import 'liquid_glass_accessibility.dart';
import 'liquid_glass_config.dart';

/// A [ThemeExtension] that provides centralized liquid glass styling
/// across an application's widget tree.
///
/// Configure once in your [ThemeData.extensions] and have all liquid glass
/// components inherit unified configs and accessibility policies:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const <ThemeExtension<dynamic>>[
///       LiquidGlassThemeData(
///         defaultConfig: LiquidGlassConfig.regular(),
///         cardConfig: LiquidGlassConfig.frosted(),
///         buttonConfig: LiquidGlassConfig.crystal(),
///       ),
///     ],
///   ),
/// );
/// ```
@immutable
class LiquidGlassThemeData extends ThemeExtension<LiquidGlassThemeData> {
  /// Creates a unified liquid glass theme.
  const LiquidGlassThemeData({
    this.defaultConfig,
    this.cardConfig,
    this.buttonConfig,
    this.navBarConfig,
    this.inputConfig,
    this.overlayConfig,
    this.accessibility,
  });

  /// Fallback configuration used when a component has no specific config.
  final LiquidGlassConfig? defaultConfig;

  /// Default configuration for [LiquidGlassCard] widgets.
  final LiquidGlassConfig? cardConfig;

  /// Default configuration for [LiquidGlassButton] and [LiquidGlassFAB] widgets.
  final LiquidGlassConfig? buttonConfig;

  /// Default configuration for [LiquidGlassNavBar] and navigation surfaces.
  final LiquidGlassConfig? navBarConfig;

  /// Default configuration for [LiquidGlassTextField], [LiquidGlassSwitch],
  /// and [LiquidGlassSlider] inputs.
  final LiquidGlassConfig? inputConfig;

  /// Default configuration for dialogs, bottom sheets, and tooltips.
  final LiquidGlassConfig? overlayConfig;

  /// Default accessibility and fallback policy across all surfaces.
  final LiquidGlassAccessibilityPolicy? accessibility;

  /// Retrieves the nearest [LiquidGlassThemeData] from the widget tree,
  /// or returns a default instance if none is found.
  static LiquidGlassThemeData of(BuildContext context) {
    return Theme.of(context).extension<LiquidGlassThemeData>() ??
        const LiquidGlassThemeData();
  }

  @override
  LiquidGlassThemeData copyWith({
    LiquidGlassConfig? defaultConfig,
    LiquidGlassConfig? cardConfig,
    LiquidGlassConfig? buttonConfig,
    LiquidGlassConfig? navBarConfig,
    LiquidGlassConfig? inputConfig,
    LiquidGlassConfig? overlayConfig,
    LiquidGlassAccessibilityPolicy? accessibility,
  }) {
    return LiquidGlassThemeData(
      defaultConfig: defaultConfig ?? this.defaultConfig,
      cardConfig: cardConfig ?? this.cardConfig,
      buttonConfig: buttonConfig ?? this.buttonConfig,
      navBarConfig: navBarConfig ?? this.navBarConfig,
      inputConfig: inputConfig ?? this.inputConfig,
      overlayConfig: overlayConfig ?? this.overlayConfig,
      accessibility: accessibility ?? this.accessibility,
    );
  }

  @override
  LiquidGlassThemeData lerp(
    ThemeExtension<LiquidGlassThemeData>? other,
    double t,
  ) {
    if (other is! LiquidGlassThemeData) return this;
    if (t < 0.5) return this;
    return other;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassThemeData &&
          defaultConfig == other.defaultConfig &&
          cardConfig == other.cardConfig &&
          buttonConfig == other.buttonConfig &&
          navBarConfig == other.navBarConfig &&
          inputConfig == other.inputConfig &&
          overlayConfig == other.overlayConfig &&
          accessibility == other.accessibility;

  @override
  int get hashCode => Object.hash(
        defaultConfig,
        cardConfig,
        buttonConfig,
        navBarConfig,
        inputConfig,
        overlayConfig,
        accessibility,
      );
}
