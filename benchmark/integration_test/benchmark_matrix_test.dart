import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

import 'package:liquid_glass_benchmark/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('repeatable native renderer matrix', (tester) async {
    const smoke = bool.fromEnvironment('BENCHMARK_MATRIX_SMOKE');
    const repetitions = smoke ? 1 : 3;
    const initialSettle = Duration(
        seconds: smoke
            ? 0
            : int.fromEnvironment('BENCHMARK_INITIAL_SETTLE_SECONDS',
                defaultValue: 60));
    const startupSettle = Duration(
        seconds: int.fromEnvironment('BENCHMARK_STARTUP_SETTLE_SECONDS',
            defaultValue: 10));
    final scenarios = <BenchmarkScenario>[
      if (smoke)
        const BenchmarkScenario(BenchmarkCase.captureBalanced)
      else ...<BenchmarkScenario>[
        for (final animated in <bool>[false, true]) ...<BenchmarkScenario>[
          for (final surfaces in <int>[1, 4, 10])
            for (final material in <BenchmarkCase>[
              BenchmarkCase.ordinary,
              BenchmarkCase.blur,
              BenchmarkCase.refraction,
              BenchmarkCase.capturePerformance,
              BenchmarkCase.captureBalanced,
              BenchmarkCase.captureUltra,
              if (LiquidGlassCapabilities.supportsShaderBackdropFilter)
                BenchmarkCase.filter,
            ])
              BenchmarkScenario(material,
                  surfaces: surfaces, animated: animated),
          BenchmarkScenario(BenchmarkCase.captureBalanced,
              surfaces: 4,
              arrangement: BenchmarkArrangement.overlapping,
              animated: animated),
          BenchmarkScenario(BenchmarkCase.captureBalanced,
              surfaces: 10,
              arrangement: BenchmarkArrangement.spread,
              animated: animated),
        ],
      ],
    ];
    final selectedName =
        Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
            .queryParameters['scenario'];
    if (const bool.fromEnvironment('BENCHMARK_REQUIRE_SCENARIO') &&
        selectedName == null) {
      throw ArgumentError('This batch binary requires a scenario launch route');
    }
    if (selectedName != null) {
      scenarios.removeWhere((scenario) => scenario.name != selectedName);
      if (scenarios.isEmpty) {
        throw ArgumentError(
            'Unknown or unsupported benchmark scenario: $selectedName');
      }
    }
    final results = <Map<String, Object?>>[];
    binding.reportData = <String, dynamic>{
      'protocol':
          '3s warmup, timestamped window, 2s drain; display frozen and no test pumping during sampling',
      'benchmarkProtocolVersion': 7,
      'smokeOnly': smoke,
      'repetitions': repetitions,
      'scenarioCount': scenarios.length,
      'startupSettleUs': startupSettle.inMicroseconds,
      'initialSettleUs': initialSettle.inMicroseconds,
      'selectedScenario': selectedName,
      'results': results,
      'completed': false,
    };
    var initialSettled = false;
    for (final scenario in scenarios) {
      for (var repetition = 1; repetition <= repetitions; repetition += 1) {
        final completion = Completer<Map<String, Object?>>();
        await tester.pumpWidget(BenchmarkApp(
            key: ValueKey('${scenario.name}-$repetition'),
            scenario: scenario,
            onResult: completion.complete));
        // Animated scenarios deliberately never settle. Bound startup instead.
        await tester.pump();
        if (!initialSettled) {
          debugPrint(
              'MATRIX_INITIAL_SETTLE seconds=${initialSettle.inSeconds}');
          await tester.runAsync(() => Future<void>.delayed(initialSettle));
          initialSettled = true;
        }
        // Android profile installation/class resolution can continue several
        // seconds after activity launch. Keep it outside the measured window.
        await tester.runAsync(() => Future<void>.delayed(startupSettle));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Start'));
        // Allow the real engine and application tickers to drive the workload.
        // WidgetTester.pump would otherwise alter the timing being measured.
        final result = await tester.runAsync(
            () => completion.future.timeout(const Duration(minutes: 2)));
        results.add(<String, Object?>{
          ...result!,
          'scenario': scenario.name,
          'repetition': repetition,
          'startupSettleUs': startupSettle.inMicroseconds,
        });
        debugPrint('MATRIX_RESULT ${scenario.name} repetition=$repetition '
            'samples=${result['sampleCount']} complete=${result['measurementComplete']}');
        expect(result['measurementComplete'], isTrue);
        expect(result['missingQualificationEvidence'],
            smoke ? contains('short-measurement-window') : isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester
            .runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      }
    }
    binding.reportData!['completed'] = true;
  }, timeout: const Timeout(Duration(minutes: 120)));
}
