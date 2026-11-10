import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> saveBenchmarkJson(String name, String json) async {
  final blob = web.Blob(
      <JSAny>[json.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final link = web.document.createElement('a') as web.HTMLAnchorElement;
  link
    ..href = url
    ..download = '$name.json';
  web.document.body!.append(link);
  link.click();
  link.remove();
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return 'Browser download: $name.json';
}

Map<String, Object?> benchmarkPlatformMetadata() => <String, Object?>{
      'userAgent': web.window.navigator.userAgent,
      'osVersion': 'See userAgent',
      'dartVersion': const String.fromEnvironment('DART_VERSION',
          defaultValue: 'unrecorded')
    };
