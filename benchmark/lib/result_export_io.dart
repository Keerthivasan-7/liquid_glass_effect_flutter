import 'dart:io';

Future<String> saveBenchmarkJson(String name, String json) async {
  const configuredDirectory = String.fromEnvironment('BENCHMARK_RESULTS_DIR');
  final mobile = Platform.isAndroid || Platform.isIOS;
  final directory = Directory(configuredDirectory.isNotEmpty
      ? configuredDirectory
      : (mobile
          ? '${Directory.systemTemp.path}/liquid_optics_results'
          : 'results'));
  await directory.create(recursive: true);
  final file = File('${directory.path}/$name.json');
  await file.writeAsString(json, flush: true);
  return file.absolute.path;
}

Map<String, Object?> benchmarkPlatformMetadata() => <String, Object?>{
      'osVersion': Platform.operatingSystemVersion,
      'dartVersion': Platform.version
    };
