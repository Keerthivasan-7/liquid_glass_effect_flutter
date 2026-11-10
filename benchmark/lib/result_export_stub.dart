Future<String> saveBenchmarkJson(String name, String json) async =>
    throw UnsupportedError('JSON file export is unavailable on this platform');

Map<String, Object?> benchmarkPlatformMetadata() =>
    <String, Object?>{'osVersion': 'unrecorded'};
