import 'dart:ui' as ui;

/// Runtime capability checks used by the renderer and diagnostics UI.
abstract final class LiquidGlassCapabilities {
  /// Whether the engine can apply a fragment shader as an image filter.
  static bool get supportsShaderBackdropFilter =>
      ui.ImageFilter.isShaderFilterSupported;

  /// A concise description suitable for diagnostics and bug reports.
  static String get rendererDescription => supportsShaderBackdropFilter
      ? 'Impeller filter and portable scope capture available'
      : 'Portable scope capture available with blur/tint fallback';
}
