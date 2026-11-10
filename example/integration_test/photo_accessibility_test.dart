import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/support/browser_runtime.dart';
import '../../test/support/photo_accessibility_suite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final view = ui.PlatformDispatcher.instance.views.first;
  final screenshots = <String, String>{};
  final observations = <String, Map<String, Object?>>{};
  final errors = <Map<String, String>>[];
  final previousReporter = reportTestException;
  reportTestException = (details, description) {
    errors.add(<String, String>{
      'test': description,
      'exception': details.exceptionAsString(),
      'stack': details.stack.toString(),
    });
    previousReporter(details, description);
  };
  binding.reportData = <String, dynamic>{
    'suite': 'photo-accessibility',
    'fixtureVersion': photoAccessibilityFixtureVersion,
    'expectedObservationCount': photoAccessibilityCaseCount,
    'pixelReadback': 'RepaintBoundary.toImage; opaque mode only',
    ...browserRuntimeMetadata(),
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'backendLabel': const String.fromEnvironment('RENDERER_LABEL',
        defaultValue: 'unrecorded'),
    'buildMode':
        kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
    'physicalWidth': view.physicalSize.width,
    'physicalHeight': view.physicalSize.height,
    'devicePixelRatio': view.devicePixelRatio,
    'refreshRateHz': view.display.refreshRate,
    'errors': errors,
    'screenshotsBase64': screenshots,
    'observations': observations,
  };
  registerPhotoAccessibilityTests(
    loadPhoto: () async =>
        (await rootBundle.load('assets/blue_marble_2002.jpg'))
            .buffer
            .asUint8List(),
    saveImage: (name, png) async => screenshots[name] = base64Encode(png),
    onObservation: (name, data) => observations[name] = data,
  );
}
