
import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 4),
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final directory = Directory(Platform.environment['LIQUID_GLASS_RESULTS']!);
    await directory.create(recursive: true);
    await File('${directory.path}/profile.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(data));
    if (data?['completed'] != true ||
        data?['benchmark']?['measurementComplete'] != true ||
        data?['benchmark']?['stopReason'] != 'duration' ||
        (data?['timeline']?['traceEvents'] as List?)?.isNotEmpty != true) {
      throw StateError('Diagnostic trace incomplete; preserved response.');
    }
  },
);
