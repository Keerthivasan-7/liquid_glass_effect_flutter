import 'dart:math' as math;
import 'dart:ui';

enum BenchmarkPhase { warming, sampling, draining, complete }

class BenchmarkFrame {
  const BenchmarkFrame(
      {required this.vsyncUs,
      required this.buildUs,
      required this.rasterUs,
      required this.totalUs});
  factory BenchmarkFrame.fromTiming(FrameTiming timing) => BenchmarkFrame(
        vsyncUs: timing.timestampInMicroseconds(FramePhase.vsyncStart),
        buildUs: timing.buildDuration.inMicroseconds,
        rasterUs: timing.rasterDuration.inMicroseconds,
        totalUs: timing.totalSpan.inMicroseconds,
      );
  final int vsyncUs;
  final int buildUs;
  final int rasterUs;
  final int totalUs;
  Map<String, int> toJson() => <String, int>{
        'vsyncUs': vsyncUs,
        'buildUs': buildUs,
        'rasterUs': rasterUs,
        'totalUs': totalUs
      };
}

/// Bounded raw sampling with an explicit warm-up and engine-timestamp window.
/// Reporting and JSON encoding happen outside the measurement callback.
class BenchmarkRun {
  BenchmarkRun({
    required this.metadata,
    this.refreshRateHz,
    this.warmup = const Duration(seconds: 3),
    this.duration = const Duration(seconds: 30),
    this.capacity = 120000,
    this.ignoreVsyncAtOrBeforeUs,
  })  : assert(capacity > 0),
        assert(!warmup.isNegative),
        assert(duration > Duration.zero),
        _buffer = List<BenchmarkFrame?>.filled(capacity, null);

  final Map<String, Object?> metadata;
  final double? refreshRateHz;
  final Duration warmup;
  final Duration duration;
  final int capacity;

  /// Discards delayed timing batches from before the user started this run.
  final int? ignoreVsyncAtOrBeforeUs;
  final List<BenchmarkFrame?> _buffer;
  final DateTime createdAtUtc = DateTime.now().toUtc();
  int _count = 0;
  int? _firstVsync;
  int? _latestVsync;
  int? _cutoffVsync;
  bool _draining = false;
  bool _complete = false;
  bool capacityReached = false;
  String stopReason = 'duration';

  int get sampleCount => _count;
  bool get measurementComplete =>
      _complete && _draining && stopReason == 'duration' && _count > 0;
  int? get samplingStartUs =>
      _firstVsync == null ? null : _firstVsync! + warmup.inMicroseconds;
  int? get samplingEndUs =>
      _cutoffVsync ??
      (samplingStartUs == null
          ? null
          : samplingStartUs! + duration.inMicroseconds);
  Iterable<BenchmarkFrame> get frames =>
      _buffer.take(_count).cast<BenchmarkFrame>();
  BenchmarkPhase get phase => _complete
      ? BenchmarkPhase.complete
      : _draining
          ? BenchmarkPhase.draining
          : (_latestVsync == null || _latestVsync! < samplingStartUs!)
              ? BenchmarkPhase.warming
              : BenchmarkPhase.sampling;

  void addTiming(FrameTiming timing) =>
      addFrame(BenchmarkFrame.fromTiming(timing));

  void addFrame(BenchmarkFrame frame) {
    if (_complete) return;
    if (ignoreVsyncAtOrBeforeUs != null &&
        frame.vsyncUs <= ignoreVsyncAtOrBeforeUs!) {
      return;
    }
    _firstVsync ??= frame.vsyncUs;
    _latestVsync = math.max(_latestVsync ?? frame.vsyncUs, frame.vsyncUs);
    if (frame.vsyncUs < samplingStartUs!) return;
    if (frame.vsyncUs >= samplingEndUs!) {
      _draining = true;
      return;
    }
    if (_count == capacity) {
      capacityReached = true;
      stopReason = 'capacity';
      _draining = true;
      _cutoffVsync = frame.vsyncUs;
      return;
    }
    _buffer[_count++] = frame;
  }

  /// Keep accepting late timing batches whose timestamps precede this cutoff.
  void stopAt(int vsyncUs, {String reason = 'manual'}) {
    _cutoffVsync = math.min(samplingEndUs ?? vsyncUs, vsyncUs);
    stopReason = reason;
    _draining = true;
  }

  void complete() => _complete = true;

  Map<String, Object?> toJson() {
    final samples = frames.toList(growable: false);
    final budgetMs = refreshRateHz != null && refreshRateHz! > 0
        ? 1000 / refreshRateHz!
        : null;
    Map<String, Object?> distribution(int Function(BenchmarkFrame) select) {
      final values = samples.map(select).toList()..sort();
      double? percentile(double p) => values.isEmpty
          ? null
          : values[((values.length - 1) * p).round()] / 1000;
      return <String, Object?>{
        'p50Ms': percentile(0.5),
        'p90Ms': percentile(0.9),
        'p99Ms': percentile(0.99),
        'worstMs': values.isEmpty ? null : values.last / 1000
      };
    }

    Map<String, Object?> exceedances(double milliseconds) {
      final build =
          samples.where((f) => f.buildUs / 1000 > milliseconds).length;
      final raster =
          samples.where((f) => f.rasterUs / 1000 > milliseconds).length;
      final either = samples
          .where((f) => math.max(f.buildUs, f.rasterUs) / 1000 > milliseconds)
          .length;
      return <String, Object?>{
        'budgetMs': milliseconds,
        'build': build,
        'raster': raster,
        'either': either,
        'eitherRate': samples.isEmpty ? null : either / samples.length
      };
    }

    return <String, Object?>{
      'schemaVersion': 1,
      'createdAtUtc': createdAtUtc.toIso8601String(),
      'metadata': Map<String, Object?>.of(metadata),
      'warmupUs': warmup.inMicroseconds,
      'ignoreVsyncAtOrBeforeUs': ignoreVsyncAtOrBeforeUs,
      'requestedDurationUs': duration.inMicroseconds,
      'samplingStartVsyncUs': samplingStartUs,
      'samplingEndVsyncUs': samplingEndUs,
      'sampleCount': samples.length,
      'capacity': capacity,
      'capacityReached': capacityReached,
      'stopReason': stopReason,
      'complete': _complete,
      'measurementComplete': measurementComplete,
      'refreshRateHz': refreshRateHz,
      'frameBudgetMs': budgetMs,
      'percentileMethod':
          'nearest index to (n - 1) * p in sorted raw microseconds',
      'build': distribution((f) => f.buildUs),
      'raster': distribution((f) => f.rasterUs),
      'totalSpan': distribution((f) => f.totalUs),
      'budgetExceedances': <String, Object?>{
        'reference120Hz': exceedances(8.33),
        'reference60Hz': exceedances(16.67),
        if (budgetMs != null) 'display': exceedances(budgetMs),
      },
      'frames': samples.map((frame) => frame.toJson()).toList(growable: false),
    };
  }
}
