import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_benchmark/benchmark_run.dart';
import 'package:liquid_glass_benchmark/main.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  test('delayed pre-start frames cannot shorten the warm-up', () {
    final run = BenchmarkRun(
        metadata: <String, Object?>{}, ignoreVsyncAtOrBeforeUs: 1000000);
    for (final timestamp in <int>[0, 500000, 1000000]) {
      run.addFrame(BenchmarkFrame(
          vsyncUs: timestamp, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    }
    expect(run.samplingStartUs, isNull);
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 1010000, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    expect(run.samplingStartUs, 4010000);
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 4009999, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    expect(run.sampleCount, 0);
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 4010000, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    expect(run.sampleCount, 1);
  });
  test('quality cases change only the sampling-quality setting', () {
    final balanced = benchmarkConfigurationFor(BenchmarkCase.captureBalanced);
    expect(
        benchmarkConfigurationFor(BenchmarkCase.capturePerformance)
            .copyWith(quality: LiquidGlassQuality.balanced),
        balanced);
    expect(
        benchmarkConfigurationFor(BenchmarkCase.captureUltra)
            .copyWith(quality: LiquidGlassQuality.balanced),
        balanced);
  });
  test('warm-up and cutoff use frame timestamps, including late timing batches',
      () {
    final run = BenchmarkRun(
        metadata: <String, Object?>{},
        refreshRateHz: 120,
        warmup: const Duration(seconds: 1),
        duration: const Duration(seconds: 3));
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 100, buildUs: 90000, rasterUs: 90000, totalUs: 180000));
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 1000100, buildUs: 1000, rasterUs: 2000, totalUs: 3000));
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 2000100, buildUs: 2000, rasterUs: 9000, totalUs: 11000));
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 4000100, buildUs: 90000, rasterUs: 90000, totalUs: 180000));
    expect(run.phase, BenchmarkPhase.draining);
    // Frame timings can arrive after the window closes. A late frame inside
    // that window must still count; the first frame beyond it must not.
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 3000100, buildUs: 3000, rasterUs: 20000, totalUs: 23000));
    expect(run.sampleCount, 3);
    run.complete();
    expect(run.measurementComplete, isTrue);
    final report = run.toJson();
    expect((report['build'] as Map)['p50Ms'], 2);
    expect((report['raster'] as Map)['p90Ms'], 20);
    expect(
        ((report['budgetExceedances'] as Map)['display'] as Map)['raster'], 2);
    expect(
        ((report['budgetExceedances'] as Map)['reference60Hz']
            as Map)['raster'],
        1);
  });

  test('raw JSON reproduces the displayed distribution and budget counts', () {
    final run = BenchmarkRun(
        metadata: <String, Object?>{},
        refreshRateHz: 60,
        warmup: Duration.zero);
    for (final value in <int>[1000, 9000, 3000, 7000, 5000]) {
      run.addFrame(BenchmarkFrame(
          vsyncUs: value,
          buildUs: value,
          rasterUs: value * 2,
          totalUs: value * 3));
    }
    run.complete();
    final report = run.toJson();
    final raw = report['frames'] as List<Map<String, int>>;
    final raster = raw.map((frame) => frame['rasterUs']!).toList()..sort();
    expect((report['raster'] as Map)['p50Ms'], raster[2] / 1000);
    expect((report['raster'] as Map)['worstMs'], 18);
    expect(
        ((report['budgetExceedances'] as Map)['reference60Hz']
            as Map)['raster'],
        raster.where((us) => us > 16670).length);
    expect((report['build'] as Map)['p90Ms'], 9);
  });

  test('the raw buffer is bounded and records capacity termination', () {
    final run = BenchmarkRun(
        metadata: <String, Object?>{}, warmup: Duration.zero, capacity: 2);
    for (var frame = 0; frame < 10; frame += 1) {
      run.addFrame(BenchmarkFrame(
          vsyncUs: frame, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    }
    expect(run.sampleCount, 2);
    expect(run.capacityReached, isTrue);
    expect(run.stopReason, 'capacity');
    expect(run.phase, BenchmarkPhase.draining);
  });

  test('manual stop excludes later frames and completion freezes the result',
      () {
    final run =
        BenchmarkRun(metadata: <String, Object?>{}, warmup: Duration.zero);
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 100, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    run.stopAt(200);
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 199, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 200, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    run.complete();
    run.addFrame(const BenchmarkFrame(
        vsyncUs: 150, buildUs: 1000, rasterUs: 1000, totalUs: 2000));
    expect(run.sampleCount, 2);
    expect(run.toJson()['samplingEndVsyncUs'], 200);
    expect(run.measurementComplete, isFalse);
  });
}
