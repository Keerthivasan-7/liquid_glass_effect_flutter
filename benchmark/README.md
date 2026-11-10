# Repeatable renderer benchmark

Run from this directory with `flutter run --profile`. Select the material,
surface count (1/4/10), compact/overlapping/spread arrangement, capture scale,
and static or animated content. Start begins a three-second warm-up followed
by 30 seconds of sampling. Stop ends the measurement early. A two-second drain
accepts delayed FrameTiming batches whose timestamps fall inside the window.

The timing callback only collects bounded raw samples. Protocol v7 freezes the
display through warm-up, sampling and timing drain; idle display refresh remains
four Hz. Start/Stop and completion still update controls. A vsync ticker requests frames during measurement even
for the static-content case. This measures the implemented retained-scene path;
it does not force a full content repaint in the static variant.

Export JSON saves raw microsecond samples, percentiles, budget exceedances,
all optical settings, capture events, memory estimates, and run metadata.
Desktop results go to `results/`; mobile results go to the app's temporary
directory; web triggers a JSON download. `BENCHMARK_RESULTS_DIR` overrides the
native directory. Copy JSON is an explicit clipboard action.

The three capture quality cases use identical optical settings and vary only
the quality stencil. Blur fallback and refraction-without-scatter are separate
cases. Forced filter is available only where the capability check permits it.

For an automatic three-run sequence, supply compile-time labels:

```powershell
flutter run --profile -d windows `
  --dart-define=BENCHMARK_AUTORUN=true `
  --dart-define=BENCHMARK_REPETITIONS=3 `
  --dart-define=BENCHMARK_SECONDS=30 `
  --dart-define=BENCHMARK_CASE=captureBalanced `
  --dart-define=BENCHMARK_SURFACES=1 `
  --dart-define=BENCHMARK_ARRANGEMENT=compact `
  --dart-define=BENCHMARK_ANIMATED=true `
  --dart-define=BENCHMARK_QUALITY_SCALE=0.65 `
  --dart-define=FLUTTER_REVISION=ACTUAL_FRAMEWORK_REVISION `
  --dart-define=DEVICE_LABEL=ACTUAL_DEVICE `
  --dart-define=GPU_LABEL=ACTUAL_GPU_OR_EXPLICITLY_UNKNOWN `
  --dart-define=RENDERER_LABEL=ACTUAL_BACKEND `
  --dart-define=POWER_MODE=ACTUAL_POWER_STATE
```

These labels must describe the observed environment. A populated label is not
hardware verification. The result records missing labels, debug builds,
unexpected fallback, and capture failures. The app prints `BENCHMARK_RESULT`
for each file and `BENCHMARK_AUTORUN_COMPLETE` after the sequence.

Keep the app visible, stabilize thermal and power conditions, and record other
system activity. Repeat every case used by the product at least three times;
retain every run. See [the performance protocol](../doc/PERFORMANCE.md).

`integration_test/benchmark_matrix_test.dart` runs three repetitions of ordinary,
blur, each capture quality, and supported filter cases on static and animated
content, plus four overlapping and ten widely spaced surfaces. The application
and engine drive frames during sampling; the test does not pump artificial
frames. `test_driver/integration_test.dart` saves every raw result and a matrix
manifest to `LIQUID_GLASS_RESULTS` on the host. Run it with `flutter drive
--driver=test_driver/integration_test.dart
--target=integration_test/benchmark_matrix_test.dart -d DEVICE --profile`,
supplying the same observed metadata labels shown above. A smoke probe can use
`BENCHMARK_MATRIX_SMOKE=true` and `BENCHMARK_SECONDS=2`; it is explicitly marked
too short to qualify as a performance measurement.

Build/raster budget exceedances are work-duration proxies, not GPU counters or
proof of missed presentation. Use DevTools/platform tooling for GPU, energy,
and presentation analysis. Unknown fields remain unknown in published results.

## Resumable Android matrix

`tool/run_matrix.ps1` builds one profile binary and saves one scenario's three
repetitions at a time. It requires PowerShell 7.2+ and Python 3.9+.
Supply `-Flutter`, `-Adb`, `-Device`, `-DeviceLabel`,
`-GpuLabel`, `-RendererLabel`, `-PowerMode`, and an absolute `-OutputDirectory`.
Add `-IncludeFilter` only on an observed supporting backend. `-OnlyScenario`
selects an explicit subset, for example `captureBalanced-1-compact-animated`.
With filter included the full matrix has 46 configurations and 138 runs.
Use `-BuildOnly` to prepare the binary before device measurements; a later
matching invocation reuses it.

The runner checks source/dependency-lock hashes, SDK identity, validator and
device labels before reusing
a binary or completed group. It refuses a device with missing package services,
preserves failed attempts, and resumes matching qualified groups. Its default
Python command is `python`; use `-Python` to select another interpreter.

`python tool/analyze_matrix.py RESULTS_DIRECTORY` independently recomputes
percentiles and budget counts from raw frames. It checks timestamp bounds,
duplicates, paths, capture failures, metadata, identical repetitions and the
predeclared p50/p99 spread limits. The most recent attempt is authoritative;
it never chooses the best previous repetition. Each group is checked by the
runner, and the full analysis writes `analysis.json`. Exit zero qualifies only
the scenarios selected in `index.json`. Retain raw files and logs alongside it.
The checker tests run with `python -m unittest discover -s tool`.

Protocol v6 requires sixty seconds of initial active-scene settling once per
app process, then ten seconds before each repetition's separate three-second
warm-up. Each measurement lasts thirty seconds, followed by a two-second drain.
Starting manually before the initial settling period disqualifies the run.
Build with `-BuildOnly` before collecting timings. The default host-memory
preflight requires 2,048 MiB free before and
after each group; it preserves a rejected group rather than changing the
stability limits. For a physical phone, `-MinimumHostFreeMemoryMiB 0` explicitly
disables that host threshold while still recording host state. Record this
policy with the results. The runner does not close unrelated applications.

The protocol includes native Android sources and Gradle settings in the binary
identity. `android_session.ps1` verifies the installed APK's SHA-256, installs
only when it differs, and reuses the authenticated VM service for later groups.
It stops only the project's test app and removes its own port forwarding after
each group. It never uninstalls the app or disables debugging authentication.

A viewport resize, rotation or device-pixel-ratio change stops and invalidates
an active measurement with `view-metrics-changed`. Keep the phone orientation
and visible app window stable throughout each three-run group. Losing app focus
also invalidates the run. The benchmark requests portrait orientation for its
own activity. A driver failure stops the matrix, preserving the failed attempt
instead of immediately relaunching the app.

The complete physical protocol-v6 matrix collected 138 individually valid
measurements: 34 of 46 groups meet fixed repeatability limits and twelve do not.
See [all results](../doc/evidence/2026-11-10/performance-physical-current/README.md).
Its four-Hz display produced periodic build work even in the ordinary control.
Saved timestamps and bounded desktop traces motivated freezing the display in
protocol v7. No renderer quality or sampling setting changed.

Exports declare `hudRefreshHz: 0` during a v7 measurement and
`idleHudRefreshHz: 4`. The validator still reproduces historical v6 results and
rejects mixed protocols/display cadences in a repetition group. The runner
rejects v6 prepared binaries/results for v7. Fixed p50/p99 limits, warm-up,
settling and measurement windows are unchanged. New v7 device measurements are
still required; the earlier matrix has not been relabeled or made to pass.
