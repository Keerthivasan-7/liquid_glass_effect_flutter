# Performance protocol

Updated 2026-11-10. No glass speedup or complete-matrix pass is qualified. The
complete protocol-v6 phone matrix has 34 accepted and twelve unstable groups.
Protocol v7 freezes the measurement display after profiling exposed observer
work. Four focused v7 phone groups pass; the remaining forty-two groups and full
repeatability qualification remain open.
The first recorded
Windows autorun attempt timed out; its raw files and explicit invalidation are
preserved under `benchmark/results/windows-balanced-animated-1/`. Do not use
those partial or empty runs as a baseline.

The first final-source Android animated balanced group has three complete
30-second runs and independently matching raw statistics. It is **unstable**:
total-span p50 ranges from 24.590 to 33.551 ms (ratio 1.364, above the fixed
1.25 limit). Build/raster spread passes, but the whole group is rejected.
Every run is retained in `benchmark/results/android-fresh-api37-v4/` and a
whole-group repeat is separate; later repetitions are not cherry-picked.
This is an emulator observation, not physical-device or GPU performance.

## Controlled comparisons

The harness offers ordinary translucent content, blur fallback, refraction
without scatter, capture performance/balanced/ultra, and explicit Impeller
filter where supported. Independently select 1/4/10 surfaces,
compact/overlapping/spread layout, capture scale, and static/animated content.
Capture quality cases share all optical parameters except their sample stencil.

Sampling uses engine vsync timestamps: three seconds of warm-up, a 30-second
window, then two seconds to accept delayed timing batches. A bounded raw buffer
retains build/raster/total/vsync microseconds. Manual stop, timeout, hidden
window, capacity exhaustion, and missing metadata disqualify a run. In protocol
v7 the display is frozen through warm-up, sampling and drain, with four-Hz idle
refresh. Start/Stop and completion update controls. A vsync ticker keeps the
measurement alive without forcing static content to repaint.

## Procedure

Before the automated matrix, use the following repeatability thresholds:
within each identical three-run configuration, the largest stage p50 must be
at most 1.25 times the smallest, and the largest p99 at most 1.5 times the
smallest. Report configurations outside either threshold as unstable. Keep
their raw runs; investigate activity/thermal variation and rerun a complete
three-run group before treating it as a repeatable baseline. These thresholds
apply to work-duration distributions, not presentation or physical-device FPS.

1. Use a profile build on native targets or a release build in the browser.
2. Record exact SDK/framework/engine, OS/device, observed backend, GPU (or
   explicitly unknown adapter), resolution, DPR, refresh rate, power state,
   thermal conditions, and other system activity.
3. Keep the app visible and unchanged throughout each measurement.
4. Run each chosen case at least three times after warm-up. Keep every run,
   including invalid runs and their reason. Do not replace inconvenient results.
5. Export JSON. Check `measurementComplete`, `qualifiedMeasurement`, missing
   evidence, actual path, capture failures, and sample count before comparison.
6. Recompute percentiles and budget counts from the raw samples. Report each
   repetition and spread; do not pool unlike cases or backends.
7. Inspect saved visual contracts and the live workload for artifacts. A faster
   case with different optics is not an equivalent optimization.

The [benchmark guide](../benchmark/README.md) lists autorun labels and export
locations. Capture events include the logical crop, actual pixel size, union
area ratio, generation, failures, and current/retained/peak RGBA estimates.
Overlay-only hover/press should reuse a static capture. Widely separated
surfaces can make the rectangular union approach a full-scene capture.

The resumable Android runner covers 46 configurations when filter is enabled:
seven materials at 1/4/10 compact surfaces on static/animated backgrounds, plus
four overlapping and ten widely spaced balanced surfaces for both backgrounds.
Three repetitions produce 138 raw runs. A selected subset is labeled as such.
`benchmark/tool/analyze_matrix.py` independently checks raw statistics and
repetition spread; a populated metadata label alone cannot qualify a result.

## Interpretation and optimization gate

Build/raster/total distributions include p50/p90/p99/worst. Stage durations over
8.33 ms, 16.67 ms, or the reported refresh budget are work-duration proxies;
they do not prove missed presentation, GPU execution cost, energy use, or
physical display latency. Scope byte estimates are not GPU memory counters.
Use platform tools and DevTools when those quantities matter.

Capture snapshots can also run as separate raster-thread tasks outside a
frame's reported raster duration. [Flutter issue 193941](https://github.com/flutter/flutter/issues/193941)
documents this allocation/timing distinction. A lower capture raster percentile
alone therefore does not establish a cheaper renderer. Preserve total-span/raw
vsync data and inspect platform traces before comparing snapshot and filter cost.

Further performance conclusions require equivalent visual and repeatable
timing baselines. After the user directed implementation forward, constant
anisotropy rotation was moved from per-fragment shader math to a CPU-supplied
axis. Sampling counts and optical parameters are unchanged. That development
change compiles, but has no measured speedup or new runtime qualification.
The hover/press envelope correction has an earlier count-based regression
check, not an FPS claim. Shared preblur and changes to distant-surface unions
remain unimplemented candidates.

## Current measurement status (2026-11-10)

Two complete emulator three-run capture groups were retained and rejected by
the declared stability limits. The first total-span p50 spread was 1.364; the
second build p99 and total-span p99 spreads were 2.181 and 1.750. A later control
was aborted after host free memory fell to about 208 MiB. These are diagnostic
results, not a qualified performance baseline.

Protocol v6 separates binary preparation from measurement, records host memory
before and after each group, and requires 2,048 MiB free by default. It waits
sixty seconds with the active scene once per app process, then ten seconds
before each repetition's separate three-second warm-up. The measurement window
is thirty seconds with a two-second timing drain. A physical
phone can explicitly use a zero host-memory threshold while retaining host
telemetry. The APK is hash-verified and reused through authenticated debugging
sessions rather than reinstalled for each group. None of these controls changes
the predeclared optical tolerances or repeatability limits.

The physical Xiaomi ordinary-one-compact-animated control passes all fixed
spread limits across 1,705/1,704/1,707 raw samples. Its three total-span p50s
are 13.576/13.570/13.774 ms. The
[preserved raw evidence](evidence/2026-11-09/performance-physical-ordinary-v6/README.md)
includes independent recomputation, source/SDK identity and thermal/battery
readings. This is one ordinary-control case, not a glass baseline or the full
46-case matrix. The later capture group was invalidated after a viewport/focus
change. Later portrait/focus safeguards and the rotation-axis optimization
belong to different source snapshots.

Original consumer sources were reconstructed from verifiable earlier terminal
reads, with their reconstruction limits documented. Paired image probes expose
the old inward-refraction and stale-background defects; they do not supply an
equivalent original timing baseline. See
[the source record](evidence/2026-11-09/original-consumer-source/README.md).

On 10 November the user requested all tests and explicitly made the phone
available for the full matrix. That current-source run finished on 10 November:
46 case groups and 138 complete measurements. Independent raw validation passes
all individual measurements; 34 groups meet every fixed spread limit and twelve
do not. Eleven failures concern build-time p50 spread. The remaining case,
ten animated blur-fallback surfaces, fails raster and total-span p99 spread.
The runner correctly exits one: the full repeatability gate has not passed.
See [every result and attempt](evidence/2026-11-10/performance-physical-current/README.md)
and the [machine-readable summary](evidence/2026-11-10/performance-physical-current/summary.json).
A completed measurement is not automatically a repeatable group, and
repeatability does not establish a 60/120-Hz performance target.

This physical-device run records host free memory before and after each group
but explicitly uses a zero-MiB host memory gate. This follows the physical-phone
policy; it does not apply the emulator's 2-GiB gate. The independent p50 max/min
limit of 1.25 and p99 limit of 1.5 are unchanged. No before/after renderer speedup,
GPU-time, energy or presentation-FPS claim is made. The full run lasted from
05:20:51 to 08:04:47 UTC. Static variants still request frames at vsync and do
not measure idle power. Continuous temperature/clock telemetry was not captured;
the settling interval alone is not evidence of thermal stability.

In the named static one-surface scene, balanced capture raster p50 ranges from
63.61 to 63.79 ms across three runs, compared with 12.14–13.41 ms for the
ordinary control. The balanced case exceeds the phone's 16.67-ms work budget;
there is no smooth-60-Hz claim for that configuration. The ordinary scene also
has tail-budget exceedances. These are whole-scene FrameTiming measurements,
including the benchmark UI, rather than isolated shader/GPU costs. Use traces
before attributing build variation or raster cost to a particular mechanism.
Do not silently reduce optics or select only the best repetitions to close the
gate. Preserve this baseline before targeted profiling or protocol changes.

## Protocol v7: remove measurement-display build bursts

The nine static ordinary-control repetitions in the saved phone matrix contain
115–120 build durations over 8.33 ms per 30-second run. Their median spacing is
about 247.74 ms, closely matching the display's four-Hz timer. That correlation
does not by itself identify the cause of all twelve repeatability failures.

Bounded desktop traces compare the original periodic display with the actual
v7 implementation. The observer's refresh markers coincide with framework
build bursts; freezing the display removes those periodic refresh builds.
These short instrumented Windows/Skia diagnostics identify a source of observer
work. They are not a three-run performance qualification, a renderer/GPU
speedup measurement or evidence that the phone's repeatability failures are
resolved. See [the profiling record](evidence/2026-11-10/measurement-display/README.md).

The producer, runner and exported manifest now declare protocol 7. Metadata
records zero active display refresh and four-Hz idle refresh. Raw validation
requires that policy for v7, retains v6 compatibility and prevents combining
different observer workloads in one repetition group. Existing v6 analysis
reproduces exactly: 34 accepted, twelve rejected, with unchanged raw hashes.
All fixed limits and the sixty-second initial / ten-second per-repetition
settling, three-second warm-up, thirty-second window and two-second drain remain
unchanged. Device v7 results must use a new results directory and binary.

## Focused v7 phone follow-up

The user-authorized four-case follow-up completed all twelve measurements:
ordinary-one-static, capture-performance-four-static, ordinary-four-animated
and blur-ten-animated. Each three-run group passes the unchanged p50/p99 spread
limits, including the three configurations that were unstable in v6. Raw/hash
recomputation and protocol/display-policy validation pass.
See [the focused report](evidence/2026-11-10/performance-physical-v7-focused/README.md).

This covers four cases, not the full 46-case matrix. Forty-two v7 cases remain
unmeasured. Endpoint battery temperature rose from 34.9 to 37.2°C with USB power;
there is no continuous temperature/clock trace. Cross-protocol timing differences
do not establish a renderer speedup, GPU cost or presentation FPS. The old v6
data and twelve rejected groups remain unchanged. Accepted v7 groups can be
retained when resuming the same source/binary/protocol; do not rerun them without
a new reason or mix them with v6 groups.
