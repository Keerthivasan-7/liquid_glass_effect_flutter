# Physical Android current-source matrix

Snapshot: 2026-11-10T08:17:31.484690+00:00. 46/46 groups have all three measurements; 34 latest groups qualify. Measurement phase complete: **true**; all groups qualified: **false**.

Device: Xiaomi M2006C3MII, Android 10/API 29, ARMv7, MT6765 / PowerVR GE8320, Impeller OpenGLES. Flutter 3.47.9 / Dart 3.13.7, profile mode, 720x1504 physical app view, DPR 2, reported 60 Hz, USB-powered normal mode. Capture qualityScale 0.65. See each raw run for optical settings, capture bounds/storage and active paths.

Protocol v6: 60-second initial scene settle, 10-second per-repetition settle, 3-second warm-up, 30-second timestamped measurement and 2-second drain. Three repetitions per scenario; latest attempt authoritative. Host memory is recorded before/after groups with an explicit zero-MiB physical-phone gate. Statistical gates remain p50 max/min <=1.25 and p99 max/min <=1.5 independently for build, raster and total span.

Raw timing JSON files are unchanged copies, hash checked against private originals. The independent Python validator recomputed every exported run and its group spread. See [summary.json](summary.json) for every repetition, [analysis.json](analysis.json) for missing/unstable groups and [index.json](index.json) for attempt/environment metadata. Unique serials and local authenticated test URLs are redacted only from non-measurement records.

The exact stable-SDK package and benchmark dependency locks are retained under `dependencies/` with their original content hashes. They may differ from another SDK lane or the working directory's resolver output; the binary used the locks recorded in this snapshot.

Ranges below are min–max across the three per-run percentiles, in milliseconds. They describe FrameTiming work, not presentation FPS or GPU time. An unstable row remains descriptive data and does not pass qualification. Repeatability also does not establish a 60/120-Hz target. No equivalent pre-change timing baseline or measured speedup is claimed.

The static variants still request frames at vsync; they measure rendering work rather than idle power. Surface size/shape and capture union vary with count/arrangement, so the table does not establish linear per-surface scaling. Continuous device temperature/clock telemetry was not collected; a scene settling interval alone does not prove thermal stability.

## Static background

| Scenario | Status | Build p50 | Raster p50 | Raster p99 | Total-span p50 |
|---|---|---:|---:|---:|---:|
| ordinary-1-compact | Qualified | 0.85–1.04 | 12.14–13.41 | 19.22–19.64 | 14.74–16.64 |
| blur-1-compact | Qualified | 0.96–0.99 | 15.25–15.60 | 19.90–20.47 | 18.70–19.12 |
| refraction-1-compact | Qualified | 1.87–1.90 | 40.58–40.60 | 41.77–43.26 | 73.65–73.97 |
| capturePerformance-1-compact | Qualified | 1.87–1.88 | 40.53–40.54 | 41.94–42.44 | 73.80–73.89 |
| captureBalanced-1-compact | Qualified | 1.94–1.96 | 63.61–63.79 | 67.92–68.94 | 121.32–121.77 |
| captureUltra-1-compact | Qualified | 2.04–2.07 | 108.96–113.92 | 126.91–130.73 | 217.91–218.45 |
| filter-1-compact | Qualified | 1.92–2.04 | 27.06–27.13 | 28.78–29.61 | 45.80–45.93 |
| ordinary-4-compact | Qualified | 0.91–1.08 | 13.27–13.87 | 17.71–20.11 | 16.05–17.46 |
| blur-4-compact | Qualified | 0.79–0.82 | 20.34–20.47 | 24.64–26.49 | 33.24–33.55 |
| refraction-4-compact | Qualified | 2.04–2.06 | 42.85–42.85 | 43.68–45.35 | 78.27–78.61 |
| capturePerformance-4-compact | Unstable/invalid | 1.37–2.09 | 47.82–47.97 | 61.50–62.14 | 92.64–92.95 |
| captureBalanced-4-compact | Qualified | 2.13–2.15 | 67.20–67.26 | 68.67–68.91 | 128.04–128.13 |
| captureUltra-4-compact | Qualified | 2.09–2.12 | 90.15–90.23 | 94.05–94.58 | 174.04–174.36 |
| filter-4-compact | Qualified | 2.56–2.66 | 35.04–35.09 | 36.95–38.42 | 62.56–63.07 |
| ordinary-10-compact | Qualified | 1.00–1.03 | 13.66–14.08 | 18.50–19.43 | 17.02–17.78 |
| blur-10-compact | Qualified | 0.85–0.98 | 34.97–35.12 | 48.73–49.65 | 63.95–64.18 |
| refraction-10-compact | Qualified | 2.35–2.38 | 39.69–39.73 | 42.30–44.05 | 72.08–72.54 |
| capturePerformance-10-compact | Qualified | 2.31–2.33 | 39.44–39.48 | 41.83–44.73 | 71.42–71.84 |
| captureBalanced-10-compact | Qualified | 2.29–2.38 | 61.60–61.64 | 63.50–67.05 | 116.56–116.91 |
| captureUltra-10-compact | Qualified | 2.40–2.44 | 87.69–87.90 | 90.85–92.72 | 166.96–167.16 |
| filter-10-compact | Unstable/invalid | 2.19–3.65 | 44.65–45.40 | 47.16–51.82 | 82.17–83.99 |
| captureBalanced-4-overlapping | Qualified | 1.82–2.03 | 42.62–42.64 | 45.77–46.32 | 78.12–78.43 |
| captureBalanced-10-spread | Qualified | 2.42–2.42 | 63.33–63.51 | 70.99–72.01 | 122.28–122.98 |

## Animated background

| Scenario | Status | Build p50 | Raster p50 | Raster p99 | Total-span p50 |
|---|---|---:|---:|---:|---:|
| ordinary-1-compact | Qualified | 2.07–2.34 | 13.05–13.68 | 18.16–19.48 | 16.98–18.15 |
| blur-1-compact | Qualified | 1.94–2.05 | 14.49–15.01 | 19.59–19.93 | 18.48–19.07 |
| refraction-1-compact | Qualified | 2.60–2.78 | 45.35–45.49 | 48.34–49.15 | 94.00–94.48 |
| capturePerformance-1-compact | Unstable/invalid | 2.52–3.37 | 45.60–45.84 | 50.16–52.04 | 94.92–96.01 |
| captureBalanced-1-compact | Qualified | 3.69–4.19 | 68.03–68.26 | 72.33–73.24 | 139.14–140.10 |
| captureUltra-1-compact | Unstable/invalid | 3.50–4.58 | 88.61–88.94 | 92.25–94.75 | 179.96–181.87 |
| filter-1-compact | Qualified | 3.08–3.13 | 27.55–27.60 | 30.06–31.36 | 46.77–47.16 |
| ordinary-4-compact | Unstable/invalid | 1.87–2.41 | 12.73–13.99 | 19.82–20.36 | 16.52–18.63 |
| blur-4-compact | Qualified | 1.62–1.73 | 20.29–20.58 | 27.16–32.55 | 33.63–34.19 |
| refraction-4-compact | Unstable/invalid | 3.33–4.24 | 48.77–48.89 | 51.96–53.05 | 100.58–101.54 |
| capturePerformance-4-compact | Qualified | 3.52–4.13 | 49.47–49.84 | 55.29–55.69 | 103.41–104.25 |
| captureBalanced-4-compact | Unstable/invalid | 3.34–4.83 | 72.61–72.87 | 76.76–77.36 | 148.33–149.74 |
| captureUltra-4-compact | Qualified | 8.87–9.16 | 137.55–142.06 | 154.84–160.07 | 278.08–279.21 |
| filter-4-compact | Qualified | 3.45–3.50 | 34.92–34.97 | 37.89–38.76 | 62.58–62.75 |
| ordinary-10-compact | Qualified | 1.99–2.28 | 13.15–13.96 | 19.51–20.45 | 17.37–18.51 |
| blur-10-compact | Unstable/invalid | 1.64–1.74 | 34.86–36.27 | 49.55–124.44 | 64.13–67.78 |
| refraction-10-compact | Qualified | 5.07–5.18 | 46.85–46.98 | 52.65–53.43 | 97.03–97.72 |
| capturePerformance-10-compact | Unstable/invalid | 4.00–5.63 | 45.01–46.87 | 49.60–51.68 | 93.40–97.00 |
| captureBalanced-10-compact | Qualified | 4.83–5.91 | 70.05–70.70 | 75.69–78.99 | 143.85–145.07 |
| captureUltra-10-compact | Unstable/invalid | 4.38–8.56 | 87.86–89.49 | 92.31–94.55 | 179.49–182.49 |
| filter-10-compact | Unstable/invalid | 2.99–4.75 | 45.02–45.68 | 48.64–55.94 | 83.02–84.86 |
| captureBalanced-4-overlapping | Qualified | 3.42–3.83 | 47.71–47.76 | 50.84–51.95 | 97.83–98.20 |
| captureBalanced-10-spread | Unstable/invalid | 6.28–8.33 | 69.44–69.68 | 74.19–79.85 | 143.19–143.96 |
