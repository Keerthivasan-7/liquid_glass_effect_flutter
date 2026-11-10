import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      writeResponseOnFailure: true,
      responseDataCallback: (data) async {
        final directory = Directory(
            Platform.environment['LIQUID_GLASS_RESULTS'] ??
                'build/renderer-runtime');
        await directory.create(recursive: true);
        final payload = Map<String, dynamic>.of(data ?? <String, dynamic>{});
        final preceding = payload.remove('precedingContracts') as Map?;
        if (preceding != null) {
          final contractDirectory = Directory('${directory.path}/contracts');
          await contractDirectory.create(recursive: true);
          final contracts = Map<String, dynamic>.from(preceding);
          final contractImages = Map<String, dynamic>.from(
              contracts.remove('screenshotsBase64') as Map? ??
                  <String, dynamic>{});
          for (final entry in contractImages.entries) {
            if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(entry.key)) {
              throw FormatException('Invalid fixture image name: ${entry.key}');
            }
            await File('${contractDirectory.path}/${entry.key}.png')
                .writeAsBytes(base64Decode(entry.value as String));
          }
          contracts['screenshots'] =
              contractImages.keys.map((name) => '$name.png').toList();
          await File('${contractDirectory.path}/runtime.json').writeAsString(
              const JsonEncoder.withIndent('  ').convert(contracts));
          payload['precedingContracts'] = 'contracts/runtime.json';
        }
        final screenshots = Map<String, dynamic>.from(
            payload.remove('screenshotsBase64') as Map? ?? <String, dynamic>{});
        for (final entry in screenshots.entries) {
          if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(entry.key)) {
            throw FormatException('Invalid fixture image name: ${entry.key}');
          }
          await File('${directory.path}/${entry.key}.png')
              .writeAsBytes(base64Decode(entry.value as String));
        }
        payload['screenshots'] =
            screenshots.keys.map((name) => '$name.png').toList();
        payload['recordedAtUtc'] = DateTime.now().toUtc().toIso8601String();
        await File('${directory.path}/runtime.json')
            .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      },
    );
