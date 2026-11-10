import 'dart:js_interop';

@JS('performance.getEntriesByType')
external JSArray<_ResourceEntry> _entries(JSString type);

extension type _ResourceEntry(JSObject _) implements JSObject {
  external JSString get name;
}

@JS('navigator.userAgent')
external JSString get _userAgent;

@JS('crossOriginIsolated')
external JSBoolean get _isolated;

Map<String, Object?> browserRuntimeMetadata() {
  final resources = _entries('resource'.toJS)
      .toDart
      .map((entry) => entry.name.toDart)
      .where((name) => name.contains('canvaskit') || name.contains('skwasm'))
      .toList();
  final skwasm = resources.any((name) =>
      name.contains('skwasm') && Uri.parse(name).path.endsWith('.wasm'));
  final canvasKit = resources.any((name) => name.contains('canvaskit.wasm'));
  return <String, Object?>{
    'userAgent': _userAgent.toDart,
    'crossOriginIsolated': _isolated.toDart,
    'rendererResources': resources,
    'observedRenderer': skwasm && !canvasKit
        ? 'skwasm'
        : canvasKit && !skwasm
            ? 'CanvasKit'
            : 'ambiguous-or-unobserved',
  };
}
