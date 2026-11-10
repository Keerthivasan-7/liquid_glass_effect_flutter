import 'package:flutter/widgets.dart';

import 'liquid_glass_scope.dart';

/// A two-plane scene that keeps refractable content separate from glass.
///
/// [content] is painted and captured first. [glass] is then painted above it
/// and is never part of its own backdrop texture. Prefer this widget for app
/// shells, floating navigation, toolbars, and contextual controls.
class LiquidGlassScene extends StatelessWidget {
  const LiquidGlassScene({
    required this.content,
    required this.glass,
    this.pixelRatio,
    this.qualityScale = 0.65,
    this.onDiagnosticsChanged,
    super.key,
  });

  final Widget content;
  final Widget glass;
  final double? pixelRatio;
  final double qualityScale;
  final ValueChanged<LiquidGlassDiagnostics>? onDiagnosticsChanged;

  @override
  Widget build(BuildContext context) => LiquidGlassScope(
        background: content,
        pixelRatio: pixelRatio,
        qualityScale: qualityScale,
        onDiagnosticsChanged: onDiagnosticsChanged,
        child: glass,
      );
}
