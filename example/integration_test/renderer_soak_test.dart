// Qualification intentionally inspects internal image ownership after disposal.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';
import 'package:liquid_glass_effect_flutter/src/widgets/liquid_glass_scope.dart';

import '../../test/support/renderer_fixture.dart';
import 'support/android_surface_readback.dart';

/// Native profile test. Use SOAK_SECONDS=600 for milestone qualification.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final nativeReadback = usesAndroidSurfaceReadback;
  if (nativeReadback) {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }
  testWidgets('animated capture survives repeated scope mount and disposal',
      (tester) async {
    final requested = Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
        .queryParameters['seconds'];
    final seconds = requested == null
        ? const int.fromEnvironment('SOAK_SECONDS', defaultValue: 600)
        : int.parse(requested);
    if (seconds < 10 || seconds > 600) {
      throw ArgumentError('Soak seconds must be between 10 and 600');
    }
    final samples = <Map<String, Object?>>[];
    final precedingContracts = binding.reportData;
    binding.reportData = <String, dynamic>{
      if (precedingContracts != null) 'precedingContracts': precedingContracts,
      'fixtureVersion': RendererFixture.version,
      'pixelReadback': nativeReadback
          ? 'Android PixelCopy SurfaceView; analytical gradient reference'
          : 'RepaintBoundary/source image',
      'platform': defaultTargetPlatform.name,
      'buildMode':
          kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
      'backendLabel': const String.fromEnvironment('RENDERER_LABEL',
          defaultValue: 'unrecorded'),
      'requestedSeconds': seconds,
      'qualifiesTenMinuteWindow': seconds >= 600,
      'samples': samples,
      'completed': false,
    };
    final watch = Stopwatch()..start();
    var nextSample = 0;
    var nextDispose = 5;
    var mounts = 0;
    var frames = 0;
    var captures = 0;
    var changedSamples = 0;
    int? previousSignature;
    LiquidGlassCaptureHandle? handle;
    LiquidGlassRenderPath? path;
    while (watch.elapsed.inSeconds < seconds) {
      final phase = (math.sin(watch.elapsedMilliseconds / 900) + 1) / 2;
      await tester.pumpWidget(MaterialApp(
          initialRoute: '/',
          home: RendererFixture(
            config: coordinateGlassConfig,
            backdrop: FixtureBackdrop.gradient,
            phase: phase,
            qualityScale: 0.7,
            onPath: (value) => path = value,
            additionalSurfaces: mounts.isEven
                ? const <Rect>[
                    Rect.fromLTWH(15, 15, 65, 45),
                    Rect.fromLTWH(310, 220, 65, 45),
                    Rect.fromLTWH(310, 20, 65, 45)
                  ]
                : const <Rect>[],
          )));
      await tester.pump(const Duration(milliseconds: 16));
      // A newly mounted lens asynchronously acquires its fragment program.
      // Check actual refraction only after that initial frame has settled.
      if (handle == null) await tester.pumpAndSettle();
      frames += 1;
      handle ??=
          liquidGlassCaptureOf(tester.element(find.byType(LiquidGlass).first));
      if (watch.elapsed.inSeconds >= nextSample && handle!.image != null) {
        expect(path, LiquidGlassRenderPath.capture);
        final data = handle.diagnostics;
        expect(data.captureFailures, 0);
        expect(data.retiredImageCount, lessThanOrEqualTo(6));
        // This bounds tracked RGBA allocations, not the driver's GPU memory.
        final fullScopeBytes =
            (400 * data.pixelRatio).ceil() * (300 * data.pixelRatio).ceil() * 4;
        expect(data.retainedBytes, lessThanOrEqualTo(fullScopeBytes * 7));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(RendererFixture.boundaryKey));
        final signature = await tester.runAsync(() async {
          if (nativeReadback) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final output = await readAndroidSurface(tester, includePng: false);
            int indexAt(int x, int y) =>
                (((output.origin.dy + y) * output.pixelRatio).floor() *
                        output.width +
                    ((output.origin.dx + x) * output.pixelRatio).floor()) *
                4;
            // This probe is inside the flat, unshifted part of the lens but
            // away from the gradient's constant center. No GPU-source readback
            // is needed to check that the displayed generation is current.
            final x = ((output.origin.dx + 200) * output.pixelRatio).floor();
            final y = ((output.origin.dy + 120) * output.pixelRatio).floor();
            final point = Offset(
                (x + 0.5) / output.pixelRatio - output.origin.dx,
                (y + 0.5) / output.pixelRatio - output.origin.dy);
            final expected =
                fixtureGradientColorAt(RendererFixture.size, phase, point);
            final channels = <double>[
              expected.r * 255,
              expected.g * 255,
              expected.b * 255
            ];
            final flatIndex = indexAt(200, 120);
            final topX = ((output.origin.dx + 200) * output.pixelRatio).floor();
            final topY = ((output.origin.dy + 85) * output.pixelRatio).floor();
            final topPoint = Offset(
                (topX + 0.5) / output.pixelRatio - output.origin.dx,
                (topY + 0.5) / output.pixelRatio - output.origin.dy);
            final topExpected =
                fixtureGradientColorAt(RendererFixture.size, phase, topPoint);
            final topIndex = indexAt(200, 85);
            binding.reportData!['lastNativeProbe'] = <String, Object?>{
              'phase': phase,
              'flatRgb': output.rgba.sublist(flatIndex, flatIndex + 3),
              'flatExpectedRgb': channels,
              'bevelRed': output.rgba[topIndex],
              'straightBackdropRed': topExpected.r * 255,
            };
            for (var channel = 0; channel < 3; channel += 1) {
              expect(output.rgba[flatIndex + channel],
                  closeTo(channels[channel], 4),
                  reason:
                      'The flat interior must show the current analytical backdrop');
            }
            expect(output.rgba[topIndex], lessThan(topExpected.r * 255 - 2),
                reason: 'The bevel must actually refract the moving backdrop');
            final index = indexAt(120, 100);
            return output.rgba[index] * 65536 +
                output.rgba[index + 1] * 256 +
                output.rgba[index + 2];
          }
          final output = await boundary.toImage(pixelRatio: 1);
          try {
            final pixels =
                (await output.toByteData(format: ui.ImageByteFormat.rawRgba))!
                    .buffer
                    .asUint8List();
            final background = handle!.image!;
            final source = (await background.toByteData(
                    format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
            final x = ((200 - data.captureRect.left) * data.pixelRatio).floor();
            final y = ((150 - data.captureRect.top) * data.pixelRatio).floor();
            for (var channel = 0; channel < 3; channel += 1) {
              expect(pixels[(150 * output.width + 200) * 4 + channel],
                  closeTo(source[(y * background.width + x) * 4 + channel], 4),
                  reason: 'The flat interior must show the current background');
            }
            return pixels[(100 * output.width + 120) * 4] * 65536 +
                pixels[(100 * output.width + 120) * 4 + 1] * 256 +
                pixels[(100 * output.width + 120) * 4 + 2];
          } finally {
            output.dispose();
          }
        });
        if (previousSignature != null && previousSignature != signature) {
          changedSamples += 1;
        }
        previousSignature = signature;
        samples.add(<String, Object?>{
          'elapsedMs': watch.elapsedMilliseconds,
          'frames': frames,
          'mounts': mounts + 1,
          'generation': data.generation,
          'capturesThisMount': data.captureCount,
          'retiredImages': data.retiredImageCount,
          'retainedBytes': data.retainedBytes,
          'peakRetainedBytes': data.peakRetainedBytes,
          'processRssBytes': ProcessInfo.currentRss,
          'signature': signature,
        });
        if (samples.length % 30 == 0) {
          debugPrint('SOAK_PROGRESS elapsedMs=${watch.elapsedMilliseconds} '
              'samples=${samples.length} frames=$frames disposedScopes=$mounts '
              'retainedBytes=${data.retainedBytes}');
        }
        nextSample = watch.elapsed.inSeconds + 1;
      }
      if (watch.elapsed.inSeconds >= nextDispose) {
        captures += handle!.diagnostics.captureCount;
        await tester.pumpWidget(const SizedBox());
        for (var frame = 0; frame < 4; frame += 1) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(handle.image, isNull);
        expect(handle.diagnostics.retainedBytes, 0);
        handle = null;
        path = null;
        mounts += 1;
        nextDispose = watch.elapsed.inSeconds + 5;
      }
      expect(tester.takeException(), isNull);
    }
    captures += handle?.diagnostics.captureCount ?? 0;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(handle?.image, isNull);
    expect(samples.length, greaterThan(seconds * 0.7));
    expect(changedSamples, greaterThan(samples.length * 0.75));
    expect(mounts, greaterThanOrEqualTo(seconds ~/ 6));
    binding.reportData!.addAll(<String, dynamic>{
      'completed': true,
      'elapsedMs': watch.elapsedMilliseconds,
      'frames': frames,
      'disposedScopes': mounts + (handle == null ? 0 : 1),
      'captures': captures,
      'changedSamples': changedSamples,
      'memoryNote':
          'RSS includes the engine, test runner and allocator caches; '
              'retainedBytes estimates only scope-owned RGBA images.',
    });
  }, timeout: const Timeout(Duration(minutes: 15)));
}
