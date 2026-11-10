import 'dart:ui' as ui;

/// Loads and caches the immutable program while widgets own shader instances.
abstract final class LiquidGlassShaderManager {
  static const filterAssetKey =
      'packages/liquid_optics_flutter/shaders/liquid_glass.frag';
  static const captureAssetKey =
      'packages/liquid_optics_flutter/shaders/liquid_glass_capture.frag';

  static ui.FragmentProgram? _filterProgram;
  static ui.FragmentProgram? _captureProgram;
  static Future<ui.FragmentProgram>? _filterLoad;
  static Future<ui.FragmentProgram>? _captureLoad;

  static Future<ui.FragmentProgram> loadFilter() async {
    final cached = _filterProgram;
    if (cached != null) return cached;
    final pending =
        _filterLoad ??= _load(filterAssetKey, 'shaders/liquid_glass.frag');
    try {
      return _filterProgram = await pending;
    } finally {
      _filterLoad = null;
    }
  }

  static Future<ui.FragmentProgram> loadCapture() async {
    final cached = _captureProgram;
    if (cached != null) return cached;
    final pending = _captureLoad ??=
        _load(captureAssetKey, 'shaders/liquid_glass_capture.frag');
    try {
      return _captureProgram = await pending;
    } finally {
      _captureLoad = null;
    }
  }

  static Future<ui.FragmentProgram> _load(
    String packageAssetKey,
    String localAssetKey,
  ) async {
    try {
      return await ui.FragmentProgram.fromAsset(packageAssetKey);
    } on Object {
      // Package tests and the package's own example bundle shaders at their
      // local key; downstream applications use the `packages/` key.
      return ui.FragmentProgram.fromAsset(localAssetKey);
    }
  }
}
