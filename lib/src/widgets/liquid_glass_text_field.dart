import 'package:flutter/foundation.dart';
// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../configuration/liquid_glass_theme.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A text input field styled with frosted liquid glass and responsive focus sheen.
class LiquidGlassTextField extends StatefulWidget {
  /// Creates a liquid glass text input field.
  const LiquidGlassTextField({
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
    this.config,
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.borderRadius = 16.0,
    this.lightingController,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    super.key,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Initial text if [controller] is null.
  final String? initialValue;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// Custom decoration overrides.
  final InputDecoration? decoration;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// Whether this text field should focus itself if nothing else is focused.
  final bool autofocus;

  /// Whether to hide the text being edited (e.g. for passwords).
  final bool obscureText;

  /// The maximum number of lines for the text. Defaults to 1.
  final int? maxLines;

  /// The minimum number of lines for the text.
  final int? minLines;

  /// The maximum number of characters to allow.
  final int? maxLength;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user indicates that they are done editing.
  final ValueChanged<String>? onSubmitted;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Whether the text field is interactive.
  final bool enabled;

  /// Custom optical material configuration.
  final LiquidGlassConfig? config;

  /// Accessibility and fallback policy.
  final LiquidGlassAccessibilityPolicy accessibility;

  /// Corner radius of the input container squircle. Defaults to 16.0.
  final double borderRadius;

  /// Optional lighting controller to synchronize dynamic specular highlights.
  final ValueListenable<Offset>? lightingController;

  /// Shorthand hint text.
  final String? hintText;

  /// Shorthand label text.
  final String? labelText;

  /// Shorthand prefix icon.
  final Widget? prefixIcon;

  /// Shorthand suffix icon.
  final Widget? suffixIcon;

  /// Shorthand error text; triggers error tint when non-null.
  final String? errorText;

  @override
  State<LiquidGlassTextField> createState() => _LiquidGlassTextFieldState();
}

class _LiquidGlassTextFieldState extends State<LiquidGlassTextField> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      widget.focusNode?.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _effectiveFocusNode.hasFocus) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = LiquidGlassThemeData.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseConfig = widget.config ??
        glassTheme.inputConfig ??
        glassTheme.defaultConfig ??
        const LiquidGlassConfig.frosted();

    final hasError = widget.errorText != null;

    final effectiveConfig = baseConfig.copyWith(
      blurSigma: _isFocused ? 14.0 : 10.0,
      specularStrength: _isFocused ? 0.75 : 0.45,
      fresnelStrength: _isFocused ? 0.70 : 0.50,
      innerShadow: _isFocused ? 0.28 : 0.18,
      tint: hasError
          ? Colors.red.withValues(alpha: 0.18)
          : _isFocused
              ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.18)
                  : theme.colorScheme.primary.withValues(alpha: 0.10))
              : (isDark ? const Color(0x280B1120) : const Color(0x18FFFFFF)),
      absorptionColor: hasError
          ? const Color(0xFFFFE5E5)
          : isDark
              ? const Color(0xFF0D1424)
              : Colors.white,
      absorptionStrength: hasError ? 0.5 : (isDark ? 0.35 : 0.2),
      borderWidth: _isFocused ? 1.5 : 0.8,
    );

    final inputDecoration =
        (widget.decoration ?? const InputDecoration()).copyWith(
      hintText: widget.hintText ?? widget.decoration?.hintText,
      labelText: widget.labelText ?? widget.decoration?.labelText,
      prefixIcon: widget.prefixIcon ?? widget.decoration?.prefixIcon,
      suffixIcon: widget.suffixIcon ?? widget.decoration?.suffixIcon,
      errorText: widget.errorText ?? widget.decoration?.errorText,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: widget.decoration?.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: _isFocused
            ? <BoxShadow>[
                BoxShadow(
                  color: (hasError ? Colors.red : theme.colorScheme.primary)
                      .withValues(alpha: 0.25),
                  blurRadius: 12.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: LiquidGlass(
        config: effectiveConfig,
        accessibility: widget.accessibility,
        lightingController: widget.lightingController,
        shape: LiquidGlassShape.roundedRectangle(
          borderRadius: widget.borderRadius,
        ),
        interactive: false,
        child: TextField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          decoration: inputDecoration,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: widget.style ??
              TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
              ),
          textAlign: widget.textAlign,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          enabled: widget.enabled,
        ),
      ),
    );
  }
}
