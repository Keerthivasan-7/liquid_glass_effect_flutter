# Measurement display profiling and protocol v7

This record identifies periodic work in the benchmark itself. It does not
qualify a renderer speedup or resolve the phone's twelve unstable groups.

## Saved phone observation

The nine static ordinary-control repetitions in the unchanged protocol-v6
phone baseline contain 115–120 build durations over 8.33 ms per thirty-second
window. Their median spacing is approximately 247.74 ms, with four-Hz phase
coherence above 0.99. See [the calculation](phone-pulse-analysis.json) and
[the complete baseline](../performance-physical-current/README.md).
The cadence matches the display timer; this observation alone is correlation.

## Bounded desktop diagnostics

Both diagnostics use Flutter 3.47.9 profile, Windows/Skia, an ordinary animated
control, the same optical/scene settings and a 1582x853 physical view at DPR
1.25. Neither diagnostic supplies a known power mode or sixty-second initial
settle. These are deliberately short ten-second diagnostic measurements, not
qualified thirty-second repetition groups. The GPU string is a host-adapter
label; this Windows app's adapter selection was not independently measured.
They do not measure GPU time,
presentation FPS, energy or phone performance.

Each trace records two seconds inside its measurement window. Dart/GC streams
and bounded capture avoid the buffer wrapping encountered during exploratory
whole-run captures. Both accepted trace spans are fully inside the raw window
and below the event-buffer capacity. No aggregate before/after speedup is
inferred from one clip per variant.

| Observation in bounded trace | Original periodic display | Implemented frozen display |
|---|---:|---:|
| Active display-refresh markers | 8 | 0 |
| First framework BUILD after each marker, median | 1,034 µs (8 builds) | No active refresh markers |
| Framework BUILDs without a recent refresh marker, median | 25 µs | 25 µs |
| Maximum framework BUILD without a recent marker | 81 µs | 46 µs |

The trace ties the refresh request to subsequent framework build bursts; the
matching frozen implementation removes these periodic refresh builds. Raw
events and FrameTiming exports remain available in
[baseline](bounded-baseline/profile.json) and
[implemented](bounded-implemented/profile.json), with the
[recomputed comparison](analysis.json). The retained rejected implemented
attempt is separate; its early-stop cause is unknown because that diagnostic's
older harness exported only timeline data. It is not a passing observation.

## Implementation and validation

Protocol v7 skips periodic display notifications throughout warm-up, sampling
and drain. Idle refresh remains four Hz. Start/Stop and completion update
controls, and a static measuring label explains when results appear. Rendering,
scene animation, diagnostics collection, sample windows and all optical
parameters remain unchanged.

- The UI regression fails when the original periodic callback is restored in
  the isolated checkout; [defect output](regression-defect.log). The current
  benchmark suite passes ten checks, including Stop and focus/viewport
  invalidation: [output](benchmark-tests.log).
- The independent validator passes seventeen checks, accepts historical v6,
  enforces the v7 display policy, and rejects mixed/relabelled observer
  workloads. The runner's version/source checks prevent old APK/results reuse.
- Recomputing the full old analysis with the new validator produces the
  identical result and raw hashes: 34 accepted groups, twelve rejected.
  The original 138 files are unchanged.
- All fifteen library/shader source hashes still match the published renderer.
  Only the measurement harness and validation/documentation changed.

[Provenance](provenance.json) includes source hashes, SDK identity, diagnostic
sources, AOT hashes and original/public trace hashes. Local authenticated service
URLs are redacted from public strings; timing samples remain unchanged. Native
binaries and exploratory traces remain private in `.research/`.
Frozen diagnostic source is stored as `.dart.txt`; restore the `.dart` filenames
in the isolated benchmark checkout to reproduce the diagnostic. These snapshots
are evidence, separate from the application's analyzed source.

Recompute the tables with `python analyze.py` and
`python analyze_phone_pulses.py` from this directory. Both use only Python's
standard library and reproduce the checked-in analysis from public raw files.

The [focused v7 phone follow-up](../performance-physical-v7-focused/README.md)
passes all twelve measurements in four selected cases; forty-two cases remain
unmeasured. Full device qualification for v7 remains open. Keep historical v6 and new v7 results
separate; do not relax the fixed p50/p99 limits or reinterpret earlier failures
as passes.
