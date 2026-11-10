import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 125),
      writeResponseOnFailure: true,
      responseDataCallback: (data) async {
        final directory = Directory(
            Platform.environment['LIQUID_GLASS_RESULTS'] ?? 'results/matrix');
        await directory.create(recursive: true);
        final payload = Map<String, dynamic>.of(data ?? <String, dynamic>{});
        final results = payload.remove('results') as List? ?? <dynamic>[];
        final names = <String>[];
        for (var i = 0; i < results.length; i += 1) {
          final result = Map<String, dynamic>.from(results[i] as Map);
          final scenario = result['scenario'] as String;
          if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(scenario)) {
            throw FormatException('Invalid scenario: $scenario');
          }
          final name = '${i + 1}-$scenario-run-${result['repetition']}.json';
          await File('${directory.path}/$name').writeAsString(
              const JsonEncoder.withIndent('  ').convert(result));
          names.add(name);
        }
        payload['results'] = names;
        payload['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
        await File('${directory.path}/matrix.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      },
    );
