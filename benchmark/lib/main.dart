import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

import 'benchmark_run.dart';
import 'result_export.dart';

void main() => runApp(const BenchmarkApp());

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({this.scenario, this.onResult, super.key});
  final BenchmarkScenario? scenario;
  final ValueChanged<Map<String, Object?>>? onResult;
  @override
  Widget build(BuildContext context) => MaterialApp(
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
        home: BenchmarkPage(scenario: scenario, onResult: onResult),
      );
}

enum BenchmarkCase {
  ordinary,
  blur,
  refraction,
  capturePerformance,
  captureBalanced,
  captureUltra,
  filter
}

enum BenchmarkArrangement { compact, overlapping, spread }

class BenchmarkScenario {
  const BenchmarkScenario(this.material,
      {this.surfaces = 1,
      this.arrangement = BenchmarkArrangement.compact,
      this.animated = true});
  final BenchmarkCase material;
  final int surfaces;
  final BenchmarkArrangement arrangement;
  final bool animated;
  String get name =>
      '${material.name}-$surfaces-${arrangement.name}-${animated ? 'animated' : 'static'}';
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({this.scenario, this.onResult, super.key});
  final BenchmarkScenario? scenario;
  final ValueChanged<Map<String, Object?>>? onResult;
  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final Stopwatch _sessionAge = Stopwatch();
  late BenchmarkCase selected = widget.scenario?.material ??
      BenchmarkCase.values.firstWhere(
        (value) => value.name == const String.fromEnvironment('BENCHMARK_CASE'),
        orElse: () => BenchmarkCase.captureBalanced,
      );
  late BenchmarkArrangement arrangement = widget.scenario?.arrangement ??
      BenchmarkArrangement.values.firstWhere(
        (value) =>
            value.name == const String.fromEnvironment('BENCHMARK_ARRANGEMENT'),
        orElse: () => BenchmarkArrangement.compact,
      );
  late int surfaceCount = widget.scenario?.surfaces ??
      const int.fromEnvironment('BENCHMARK_SURFACES', defaultValue: 1);
  late bool animatedBackground = widget.scenario?.animated ??
      const bool.fromEnvironment('BENCHMARK_ANIMATED', defaultValue: true);
  double qualityScale = double.tryParse(const String.fromEnvironment(
          'BENCHMARK_QUALITY_SCALE',
          defaultValue: '0.65')) ??
      0.65;
  final ValueNotifier<int> _hud = ValueNotifier<int>(0);
  final Stopwatch _elapsed = Stopwatch();
  final Set<String> _paths = <String>{};
  final List<(int, LiquidGlassDiagnostics)> _captureEvents =
      <(int, LiquidGlassDiagnostics)>[];
  late final Ticker _framePump;
  Timer? _hudTimer;
  Timer? _drainTimer;
  Timer? _safetyTimer;
  Timer? _automaticTimer;
  BenchmarkRun? _run;
  Map<String, Object?>? _report;
  LiquidGlassRenderPath? _activePath;
  LiquidGlassDiagnostics? _diagnostics;
  LiquidGlassDiagnostics? _captureAtStart;
  String _exportStatus = '';
  int _runIndex = 0;
  int _automaticRemaining = const bool.fromEnvironment('BENCHMARK_AUTORUN')
      ? const int.fromEnvironment('BENCHMARK_REPETITIONS', defaultValue: 3)
      : 0;

  bool get _active => _run != null && _run!.phase != BenchmarkPhase.complete;

  @override
  void initState() {
    super.initState();
    if (!_sessionAge.isRunning) _sessionAge.start();
    WidgetsBinding.instance.addObserver(this);
    if (!<int>[1, 4, 10].contains(surfaceCount)) surfaceCount = 1;
    _framePump = createTicker((_) {});
    SchedulerBinding.instance.addTimingsCallback(_record);
    _hudTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) _hud.value += 1;
    });
    if (_automaticRemaining > 0) {
      _automaticTimer = Timer(
          const Duration(
              seconds: int.fromEnvironment('BENCHMARK_START_DELAY_SECONDS',
                  defaultValue: 60)),
          _start);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_active &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      _run!.stopAt(
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds,
          reason: 'inactive-window');
      _beginDrain();
    }
  }

  @override
  void didChangeMetrics() {
    if (_active) {
      _run!.stopAt(
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds,
          reason: 'view-metrics-changed');
      _beginDrain();
    }
  }

  void _record(List<FrameTiming> timings) {
    final run = _run;
    if (run == null || run.phase == BenchmarkPhase.complete) return;
    for (final timing in timings) {
      run.addTiming(timing);
    }
    if (run.phase != BenchmarkPhase.warming) {
      _captureAtStart ??= _diagnostics;
      if (_activePath != null) _paths.add(_activePath!.name);
    }
    if (run.phase == BenchmarkPhase.draining) _beginDrain();
  }

  void _start() {
    if (!mounted || _active) return;
    final view = View.of(context);
    final refresh = view.display.refreshRate;
    _runIndex += 1;
    _paths.clear();
    _captureEvents.clear();
    _captureAtStart = null;
    _report = null;
    _exportStatus = '';
    _elapsed
      ..reset()
      ..start();
    _run = BenchmarkRun(
      ignoreVsyncAtOrBeforeUs:
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds,
      refreshRateHz: refresh > 0 ? refresh : null,
      duration: const Duration(
          seconds: int.fromEnvironment('BENCHMARK_SECONDS', defaultValue: 30)),
      metadata: <String, Object?>{
        'benchmarkProtocolVersion': 6,
        'requiredInitialSettleUs': 60000000,
        'appSessionAgeAtStartUs': _sessionAge.elapsedMicroseconds,
        ...benchmarkPlatformMetadata(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'buildMode':
            kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
        'lifecycleAtStart': WidgetsBinding.instance.lifecycleState?.name,
        'flutterRevision': const String.fromEnvironment('FLUTTER_REVISION',
            defaultValue: 'unrecorded'),
        'device': const String.fromEnvironment('DEVICE_LABEL',
            defaultValue: 'unrecorded'),
        'gpu': const String.fromEnvironment('GPU_LABEL',
            defaultValue: 'unrecorded'),
        'renderer': const String.fromEnvironment('RENDERER_LABEL',
            defaultValue: 'unrecorded'),
        'powerMode': const String.fromEnvironment('POWER_MODE',
            defaultValue: 'unrecorded'),
        'case': selected.name,
        'opticalConfig': selected == BenchmarkCase.ordinary
            ? null
            : _configurationJson(benchmarkConfigurationFor(selected)),
        'surfaceCount': surfaceCount,
        'arrangement': arrangement.name,
        'animatedBackground': animatedBackground,
        'qualityScale': qualityScale,
        'physicalWidth': view.physicalSize.width,
        'physicalHeight': view.physicalSize.height,
        'devicePixelRatio': view.devicePixelRatio,
        'refreshRateHz': refresh > 0 ? refresh : null,
        'supportsShaderFilter':
            LiquidGlassCapabilities.supportsShaderBackdropFilter,
        'hudRefreshHz': 4,
        'framePump': 'Vsync ticker; static content is not rebuilt by the pump',
        'runIndex': _runIndex,
      },
    );
    _framePump.start();
    _safetyTimer?.cancel();
    _safetyTimer =
        Timer(_run!.warmup + _run!.duration + const Duration(seconds: 10), () {
      _run?.stopAt(
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds,
          reason: 'timing-timeout');
      _beginDrain();
    });
    _hud.value += 1;
  }

  void _stop() {
    if (!_active) return;
    _automaticRemaining = 0;
    _run!.stopAt(
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds);
    _beginDrain();
    _hud.value += 1;
  }

  void _beginDrain() {
    // Keep the frame pump alive while late FrameTiming batches arrive, but
    // accept only samples inside the fixed engine-timestamp measurement window.
    _drainTimer ??= Timer(const Duration(seconds: 2), _finish);
  }

  Future<void> _finish() async {
    final run = _run;
    if (!mounted || run == null) return;
    _drainTimer = null;
    _safetyTimer?.cancel();
    _framePump.stop();
    _elapsed.stop();
    run.complete();
    final report = run.toJson();
    final metadata = report['metadata']! as Map<String, Object?>;
    metadata['activePathsDuringSampling'] = _paths.toList();
    metadata['lifecycleAtEnd'] = WidgetsBinding.instance.lifecycleState?.name;
    report['captureAtSamplingStartObserved'] = _diagnosticJson(_captureAtStart);
    report['captureAtEnd'] = _diagnosticJson(_diagnostics);
    report['captureEvents'] = _captureEvents
        .where((event) =>
            event.$1 >= (run.samplingStartUs ?? 0) &&
            event.$1 < (run.samplingEndUs ?? 0))
        .map((event) => <String, Object?>{
              'vsyncUs': event.$1,
              ..._diagnosticJson(event.$2)
            })
        .toList(growable: false);
    final missing = <String>[
      for (final key in <String>[
        'flutterRevision',
        'device',
        'gpu',
        'renderer',
        'powerMode'
      ])
        if (metadata[key] == 'unrecorded') key,
      if (kDebugMode) 'profile-or-release-build',
      if ((metadata['appSessionAgeAtStartUs']! as int) < 60000000)
        'initial-startup-settling',
      if (run.duration < const Duration(seconds: 30))
        'short-measurement-window',
      if (run.sampleCount == 0) 'frame-samples',
      if (!run.measurementComplete) 'incomplete-measurement-window',
      if (run.stopReason == 'timing-timeout') 'timing-timeout',
      if (run.stopReason == 'capacity') 'sample-capacity',
      if (<Object?>[metadata['lifecycleAtStart'], metadata['lifecycleAtEnd']]
          .any((state) =>
              state == 'inactive' || state == 'hidden' || state == 'paused'))
        'inactive-window',
      if (_paths.contains('fallback') && selected != BenchmarkCase.blur)
        'unexpected-fallback',
      if ((_diagnostics?.captureFailures ?? 0) > 0) 'capture-failure',
    ];
    report['missingQualificationEvidence'] = missing;
    report['metadataLabelsComplete'] = <String>[
      'flutterRevision',
      'device',
      'gpu',
      'renderer',
      'powerMode'
    ].every((key) => metadata[key] != 'unrecorded');
    report['qualifiedMeasurement'] = missing.isEmpty;
    _report = report;
    _hud.value += 1;
    widget.onResult?.call(report);
    if (_automaticRemaining > 0) {
      final saved = await _save();
      _automaticRemaining -= 1;
      if (saved && run.measurementComplete && _automaticRemaining > 0) {
        _automaticTimer = Timer(const Duration(seconds: 2), _start);
      } else {
        _automaticRemaining = 0;
        debugPrint('BENCHMARK_AUTORUN_COMPLETE');
      }
    }
  }

  void _recordDiagnostics(LiquidGlassDiagnostics value) {
    _diagnostics = value;
    if (_active && _captureEvents.length < 120000) {
      _captureEvents.add((
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds,
        value
      ));
    }
  }

  Future<bool> _save() async {
    final report = _report;
    if (report == null) return false;
    final stamp = (report['createdAtUtc']! as String)
        .replaceAll(RegExp('[^a-zA-Z0-9]'), '-');
    final name = '$stamp-${selected.name}-run-$_runIndex';
    try {
      final path = await saveBenchmarkJson(
          name, const JsonEncoder.withIndent('  ').convert(report));
      _exportStatus = path;
      debugPrint('BENCHMARK_RESULT $path');
      if (mounted) _hud.value += 1;
      return true;
    } on Object catch (error) {
      _exportStatus = 'Export failed: $error';
      if (mounted) _hud.value += 1;
      return false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SchedulerBinding.instance.removeTimingsCallback(_record);
    _hudTimer?.cancel();
    _drainTimer?.cancel();
    _safetyTimer?.cancel();
    _automaticTimer?.cancel();
    _framePump.dispose();
    _hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: <Widget>[
              RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _hud,
                  builder: (context, _, child) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: <Widget>[
                        Wrap(
                          spacing: 14,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            DropdownButton<BenchmarkCase>(
                              value: selected,
                              items: BenchmarkCase.values
                                  .where((value) =>
                                      value != BenchmarkCase.filter ||
                                      LiquidGlassCapabilities
                                          .supportsShaderBackdropFilter ||
                                      value == selected)
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value.name)))
                                  .toList(),
                              onChanged: _active
                                  ? null
                                  : (value) => setState(() {
                                        selected = value!;
                                        _activePath = null;
                                      }),
                            ),
                            DropdownButton<int>(
                              value: surfaceCount,
                              items: <int>[1, 4, 10]
                                  .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text('$value surfaces')))
                                  .toList(),
                              onChanged: _active
                                  ? null
                                  : (value) =>
                                      setState(() => surfaceCount = value!),
                            ),
                            DropdownButton<BenchmarkArrangement>(
                              value: arrangement,
                              items: BenchmarkArrangement.values
                                  .map((value) => DropdownMenuItem(
                                      value: value, child: Text(value.name)))
                                  .toList(),
                              onChanged: _active
                                  ? null
                                  : (value) =>
                                      setState(() => arrangement = value!),
                            ),
                            DropdownButton<double>(
                              value: qualityScale,
                              items: <double>[0.5, 0.65, 1]
                                  .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text('Scale $value')))
                                  .toList(),
                              onChanged: _active
                                  ? null
                                  : (value) =>
                                      setState(() => qualityScale = value!),
                            ),
                            FilterChip(
                                label: const Text('Animated content'),
                                selected: animatedBackground,
                                onSelected: _active
                                    ? null
                                    : (value) => setState(
                                        () => animatedBackground = value)),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            FilledButton(
                                onPressed: _active ? null : _start,
                                child: const Text('Start')),
                            OutlinedButton(
                                onPressed: _active ? _stop : null,
                                child: const Text('Stop')),
                            TextButton(
                                onPressed:
                                    _report == null || _active ? null : _save,
                                child: const Text('Export JSON')),
                            TextButton(
                                onPressed: _report == null || _active
                                    ? null
                                    : () => Clipboard.setData(ClipboardData(
                                        text: const JsonEncoder.withIndent('  ')
                                            .convert(_report))),
                                child: const Text('Copy JSON')),
                            Text(
                                '${_run?.phase.name ?? 'idle'} · ${_elapsed.elapsed.inSeconds} s · ${_run?.sampleCount ?? 0} samples'),
                          ],
                        ),
                        _metrics(),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LiquidGlassScene(
                  qualityScale: qualityScale,
                  onDiagnosticsChanged: _recordDiagnostics,
                  content: _MovingBackground(animated: animatedBackground),
                  glass: LayoutBuilder(
                      builder: (context, constraints) =>
                          _surfaces(constraints.biggest)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _metrics() {
    String distribution(String stage) {
      final values = _report?[stage] as Map<String, Object?>?;
      String number(String key) =>
          (values?[key] as num?)?.toStringAsFixed(2) ?? '—';
      return '${number('p50Ms')} / ${number('p90Ms')} / ${number('p99Ms')} ms · worst ${number('worstMs')}';
    }

    final budgets = _report?['budgetExceedances'] as Map<String, Object?>?;
    final misses120 =
        (budgets?['reference120Hz'] as Map<String, Object?>?)?['raster'];
    final misses60 =
        (budgets?['reference60Hz'] as Map<String, Object?>?)?['raster'];
    final capture = _diagnostics;
    final captureText = capture == null
        ? 'none'
        : '${capture.captureCount} captures · ${capture.activeSurfaceCount} surfaces · crop ${(capture.captureAreaRatio * 100).toStringAsFixed(1)}% · current/retained/peak ${(capture.estimatedBytes / 1048576).toStringAsFixed(2)}/${(capture.retainedBytes / 1048576).toStringAsFixed(2)}/${(capture.peakRetainedBytes / 1048576).toStringAsFixed(2)} MiB';
    return SizedBox(
      height: 122,
      child: Column(
        children: <Widget>[
          Text(
              'Path: ${_activePath?.name ?? 'none'} · display ${View.of(context).display.refreshRate.toStringAsFixed(1)} Hz'),
          Text('Capture: $captureText',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Build p50/p90/p99: ${distribution('build')}'),
          Text('Raster p50/p90/p99: ${distribution('raster')}'),
          Text(
              'Raster misses >8.33/>16.67 ms (work proxy): ${misses120?.toString() ?? '—'} / ${misses60?.toString() ?? '—'}'),
          Text(_exportStatus, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _surfaces(Size viewport) {
    final columns = surfaceCount == 1 ? 1 : (surfaceCount == 4 ? 2 : 5);
    final rows = (surfaceCount / columns).ceil();
    final width = surfaceCount == 1
        ? math.min(280.0, viewport.width * 0.72)
        : math.min(150.0, (viewport.width - 40) / columns - 8);
    final height = math
        .min(
            surfaceCount == 1 ? 180.0 : 85.0, (viewport.height - 32) / rows - 8)
        .clamp(16.0, 180.0);
    final config = benchmarkConfigurationFor(selected);
    return Stack(
      children: List<Widget>.generate(surfaceCount, (index) {
        final col = index % columns;
        final row = index ~/ columns;
        final blockWidth = width * columns + (columns - 1) * 8;
        final blockHeight = height * rows + (rows - 1) * 8;
        final double left;
        final double top;
        if (arrangement == BenchmarkArrangement.overlapping &&
            surfaceCount > 1) {
          left = (viewport.width - width - (surfaceCount - 1) * 12) / 2 +
              index * 12;
          top = (viewport.height - height - (surfaceCount - 1) * 6) / 2 +
              index * 6;
        } else if (arrangement == BenchmarkArrangement.spread &&
            surfaceCount > 1) {
          left = 12 +
              col * (viewport.width - width - 24) / math.max(columns - 1, 1);
          top = 12 +
              row * (viewport.height - height - 24) / math.max(rows - 1, 1);
        } else {
          left = (viewport.width - blockWidth) / 2 + col * (width + 8);
          top = (viewport.height - blockHeight) / 2 + row * (height + 8);
        }
        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: selected == BenchmarkCase.ordinary
              ? DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(28)))
              : LiquidGlass(
                  config: config,
                  onRenderPathChanged: (value) => _activePath = value,
                  child: const SizedBox(),
                ),
        );
      }),
    );
  }
}

LiquidGlassConfig benchmarkConfigurationFor(BenchmarkCase selected) =>
    switch (selected) {
      BenchmarkCase.blur => const LiquidGlassConfig.frosted()
          .copyWith(renderer: LiquidGlassRenderer.fallback),
      BenchmarkCase.refraction => const LiquidGlassConfig(
          blurSigma: 0,
          roughness: 0,
          scatteringStrength: 0,
          quality: LiquidGlassQuality.performance,
          renderer: LiquidGlassRenderer.capture),
      BenchmarkCase.capturePerformance => const LiquidGlassConfig(
          quality: LiquidGlassQuality.performance,
          renderer: LiquidGlassRenderer.capture),
      BenchmarkCase.captureUltra => const LiquidGlassConfig(
          quality: LiquidGlassQuality.ultra,
          renderer: LiquidGlassRenderer.capture),
      BenchmarkCase.filter =>
        const LiquidGlassConfig(renderer: LiquidGlassRenderer.shader),
      _ => const LiquidGlassConfig(renderer: LiquidGlassRenderer.capture),
    };

Map<String, Object?> _configurationJson(LiquidGlassConfig config) =>
    <String, Object?>{
      'blurSigma': config.blurSigma,
      'refractionStrength': config.refractionStrength,
      'fresnelStrength': config.fresnelStrength,
      'specularStrength': config.specularStrength,
      'chromaticAberration': config.chromaticAberration,
      'roughness': config.roughness,
      'transmission': config.transmission,
      'thickness': config.thickness,
      'absorptionColorArgb': config.absorptionColor.toARGB32(),
      'absorptionStrength': config.absorptionStrength,
      'scatteringStrength': config.scatteringStrength,
      'dispersionStrength': config.dispersionStrength,
      'abbeNumber': config.abbeNumber,
      'environmentStrength': config.environmentStrength,
      'coatStrength': config.coatStrength,
      'coatRoughness': config.coatRoughness,
      'coatRefractiveIndex': config.coatRefractiveIndex,
      'thinFilmThickness': config.thinFilmThickness,
      'thinFilmRefractiveIndex': config.thinFilmRefractiveIndex,
      'thinFilmStrength': config.thinFilmStrength,
      'anisotropy': config.anisotropy,
      'anisotropyRotation': config.anisotropyRotation,
      'causticStrength': config.causticStrength,
      'curvature': config.curvature,
      'refractiveIndex': config.refractiveIndex,
      'cornerSmoothing': config.cornerSmoothing,
      'innerShadow': config.innerShadow,
      'edgeWidth': config.edgeWidth,
      'maxDisplacement': config.maxDisplacement,
      'saturation': config.saturation,
      'tintArgb': config.tint.toARGB32(),
      'lightDirection': <double>[
        config.lightDirection.dx,
        config.lightDirection.dy
      ],
      'lightColorArgb': config.lightColor.toARGB32(),
      'lightIntensity': config.lightIntensity,
      'motionStrength': config.motionStrength,
      'noise': config.noise,
      'borderWidth': config.borderWidth,
      'quality': config.quality.name,
      'renderer': config.renderer.name,
      'animateLight': config.animateLight,
      'animationDurationUs': config.animationDuration.inMicroseconds,
    };

Map<String, Object?> _diagnosticJson(LiquidGlassDiagnostics? value) =>
    value == null
        ? <String, Object?>{}
        : <String, Object?>{
            'generation': value.generation,
            'captureCount': value.captureCount,
            'captureFailures': value.captureFailures,
            'activeSurfaceCount': value.activeSurfaceCount,
            'captureSupported': value.captureSupported,
            'captureRect': <String, double>{
              'left': value.captureRect.left,
              'top': value.captureRect.top,
              'width': value.captureRect.width,
              'height': value.captureRect.height
            },
            'scopeWidth': value.scopeSize.width,
            'scopeHeight': value.scopeSize.height,
            'captureAreaRatio': value.captureAreaRatio,
            'pixelWidth': value.pixelSize.width,
            'pixelHeight': value.pixelSize.height,
            'pixelRatio': value.pixelRatio,
            'currentBytes': value.estimatedBytes,
            'retainedBytes': value.retainedBytes,
            'peakRetainedBytes': value.peakRetainedBytes,
            'retiredImageCount': value.retiredImageCount,
          };

class _MovingBackground extends StatefulWidget {
  const _MovingBackground({required this.animated});
  final bool animated;
  @override
  State<_MovingBackground> createState() => _MovingBackgroundState();
}

class _MovingBackgroundState extends State<_MovingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));
  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_MovingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.animated && !controller.isAnimating) {
      controller.repeat(reverse: true);
    }
    if (!widget.animated) controller.stop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) =>
            CustomPaint(painter: _BackdropPainter(controller.value)),
      );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + phase * 2, -1),
        end: Alignment(1 - phase * 2, 1),
        colors: const <Color>[Colors.pink, Colors.indigo, Colors.cyan],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    paint
      ..shader = null
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
