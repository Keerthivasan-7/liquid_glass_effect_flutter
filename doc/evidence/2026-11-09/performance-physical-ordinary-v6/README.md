# Physical ordinary-control baseline — protocol 6

Scope: one ordinary material, one compact surface, animated content. Three
30-second profile windows after initial settling; not a glass-performance
or full-matrix claim. Raw timings are work-duration proxies, not GPU counters
or presentation FPS. The later portrait/focus safeguards are a different APK
and must be measured separately.

| Repetition | Samples | Build p50/p99 ms | Raster p50/p99 ms | Total span p50/p99 ms |
|---|---:|---:|---:|---:|
| 1 | 1705 | 1.645/15.647 | 10.778/16.128 | 13.576/27.811 |
| 2 | 1704 | 1.669/15.558 | 10.735/13.717 | 13.570/27.146 |
| 3 | 1707 | 1.669/15.622 | 10.896/13.675 | 13.774/27.685 |

The raw checker recomputes every summary and accepts all fixed p50/p99
spread limits. See analysis.json, the three raw exports, source-snapshot.json
and the SDK record. Device labels are supplied from the named phone/SDK
qualification; they are not automatic per-frame hardware attestation.
Before/after group battery and thermal readings are included. No per-stage
GPU cost, energy improvement or before/after renderer speedup is claimed.
