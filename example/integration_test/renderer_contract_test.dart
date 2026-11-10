import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

import '../../test/support/renderer_contract_suite.dart';
import '../../test/support/renderer_fixture.dart';
import '../../test/support/browser_runtime.dart';
import 'support/android_surface_readback.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final usePixelCopy = usesAndroidSurfaceReadback;
  if (usePixelCopy) {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }
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
    'fixtureVersion': RendererFixture.version,
    'pixelReadback': usePixelCopy
        ? 'Android PixelCopy SurfaceView; no ImageView conversion'
        : 'RepaintBoundary.toImage',
    ...browserRuntimeMetadata(),
    'contractFilter': Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
            .queryParameters['contract'] ??
        const String.fromEnvironment('RENDERER_CONTRACT_FILTER'),
    'errors': errors,
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'backendLabel': const String.fromEnvironment('RENDERER_LABEL',
        defaultValue: 'unrecorded'),
    'buildMode':
        kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
    'supportsShaderFilter':
        LiquidGlassCapabilities.supportsShaderBackdropFilter,
    'physicalWidth': view.physicalSize.width,
    'physicalHeight': view.physicalSize.height,
    'devicePixelRatio': view.devicePixelRatio,
    'refreshRateHz': view.display.refreshRate,
    'screenshotsBase64': screenshots,
    'observations': observations,
  };
  debugPrint(
      'RENDERER_RUNTIME filterSupported=${LiquidGlassCapabilities.supportsShaderBackdropFilter} '
      'readback=${usePixelCopy ? 'PixelCopy' : 'engine'}');
  registerRendererContractTests(
    captureVisibleView:
        usePixelCopy ? (tester, fixture) => readAndroidSurface(tester) : null,
    saveImage: (name, png) async {
      screenshots[name] = base64Encode(png);
    },
    onObservation: (name, data) => observations[name] = data,
  );
}
