# Physical Android protocol-v7 focused follow-up

Snapshot: 2026-11-10T09:48:05.364102+00:00. 4/4 groups have all three measurements; 4 latest groups qualify. Measurement phase complete: **true**; all groups qualified: **true**.

Device: Xiaomi M2006C3MII, Android 10/API 29, ARMv7, MT6765 / PowerVR GE8320, Impeller OpenGLES. Flutter 3.47.9 / Dart 3.13.7, profile mode, 720x1504 physical app view, DPR 2, reported 60 Hz, USB-powered normal mode. Capture qualityScale 0.65. See each raw run for optical settings, capture bounds/storage and active paths.

Protocol v7, display frozen while measuring: 60-second initial scene settle, 10-second per-repetition settle, 3-second warm-up, 30-second timestamped measurement and 2-second drain. Three repetitions per scenario; latest attempt authoritative. Host memory is recorded before/after groups with an explicit zero-MiB physical-phone gate. Statistical gates remain p50 max/min <=1.25 and p99 max/min <=1.5 independently for build, raster and total span.

Raw timing JSON files are unchanged copies, hash checked against private originals. The independent Python validator recomputed every exported run and its group spread. See [summary.json](summary.json) for every repetition, [analysis.json](analysis.json) for missing/unstable groups and [index.json](index.json) for attempt/environment metadata. Unique serials and local authenticated test URLs are redacted only from non-measurement records.

The exact stable-SDK package and benchmark dependency locks are retained under `dependencies/` with their original content hashes. They may differ from another SDK lane or the working directory's resolver output; the binary used the locks recorded in this snapshot.

Ranges below are min–max across the three per-run percentiles, in milliseconds. They describe FrameTiming work, not presentation FPS or GPU time. An unstable row remains descriptive data and does not pass qualification. Repeatability also does not establish a 60/120-Hz target. No equivalent pre-change timing baseline or measured speedup is claimed.

**Scope: four selected cases only. Forty-two protocol-v7 matrix cases are not covered. This follow-up cannot qualify the full matrix, and the historical v6 result remains 34 accepted and twelve rejected groups.**

The static variants still request frames at vsync; they measure rendering work rather than idle power. Surface size/shape and capture union vary with count/arrangement, so the table does not establish linear per-surface scaling. Continuous device temperature/clock telemetry was not collected; a scene settling interval alone does not prove thermal stability.

## Static background

| Scenario | Status | Build p50 | Raster p50 | Raster p99 | Total-span p50 |
|---|---|---:|---:|---:|---:|
| ordinary-1-compact | Qualified | 0.97–1.12 | 15.76–15.86 | 21.93–22.33 | 22.28–22.87 |
| capturePerformance-4-compact | Qualified | 1.59–1.69 | 43.33–43.37 | 45.05–45.64 | 80.05–80.33 |

## Animated background

| Scenario | Status | Build p50 | Raster p50 | Raster p99 | Total-span p50 |
|---|---|---:|---:|---:|---:|
| ordinary-4-compact | Qualified | 2.28–2.40 | 15.72–15.87 | 21.56–22.25 | 22.79–23.05 |
| blur-10-compact | Qualified | 1.51–1.56 | 35.01–35.10 | 48.53–55.42 | 64.02–64.21 |
