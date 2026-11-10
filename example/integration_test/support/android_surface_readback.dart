import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

import '../../../test/support/renderer_contract_suite.dart';

bool get usesAndroidSurfaceReadback =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
            .queryParameters['readback'] !=
        'engine';

/// Copies this app's SurfaceView; the rendering surface is not converted.
Future<RendererContractImage> readAndroidSurface(WidgetTester tester,
    {bool includePng = true}) async {
  const channel = MethodChannel('dev.liquid_optics_flutter/renderer_test');
  final data = (await channel.invokeMapMethod<String, dynamic>(
      'captureSurface', <String, Object>{
    'png': includePng
  }).timeout(const Duration(seconds: 10)))!;
  final scene = tester.renderObject<RenderBox>(find.byType(LiquidGlassScope));
  final transform = scene.getTransformTo(null).storage;
  final scale = ui.Offset(transform[0], transform[1]).distance;
  return RendererContractImage(
      width: data['width'] as int,
      rgba: data['rgba'] as Uint8List,
      png: data['png'] as Uint8List,
      pixelRatio: tester.view.devicePixelRatio * scale,
      origin: scene.localToGlobal(ui.Offset.zero) / scale);
}
