# Development delivery — 13 November 2026

Updated 10 November. The first development prerelease is available on
[pub.dev](https://pub.dev/packages/liquid_glass_effect_flutter). The Verified
Portable Renderer milestone remains in progress; its remaining gates are below.

## Deliverables

| Deliverable | Identity |
|---|---|
| Flutter package | `liquid_glass_effect_flutter: ^0.1.0-dev.1` |
| Published source | Git tag `v0.1.0-dev.1`, commit `954ea73f3e2523de83667dd3b7f06f11efb5edfb` |
| Canonical repository | [Keerthivasan-7/liquid_glass_effect_flutter](https://github.com/Keerthivasan-7/liquid_glass_effect_flutter) |
| Showcase | Repository `example/`: Materials, Controls and Comfort; four presets, session favorites, resettable adjustments, theme/highlight controls and accessibility previews |
| Integration instructions | [Complete guide](INTEGRATION_GUIDE.md) and [showcase instructions](../example/README.md) |
| Publication proof | [Registry archive checksum, exclusions and prepared-file hashes](evidence/2026-11-10/pub-publication.json) |

The registry archive is 628,400 bytes and contains 181 files. Its checksum
matches pub.dev; twenty-one prepared source/documentation/image hashes were
verified after download. Local research, raw evidence, build outputs and graph
caches are excluded. The source tag is immutable; later test-driver hardening
and qualification records are on GitHub main and have not been republished.

Both shaders reuse a CPU-computed rotation axis for sampling and highlights.
The optical parameters, transmission sample counts and quality settings are
unchanged. This removes repeated constant calculations but has no measured
before/after speedup claim. The structural library graph covers thirteen Dart
files: 419 nodes, 479 edges and 21 communities.

## Current checks

- Hosted [run 42761367535](https://github.com/Keerthivasan-7/liquid_glass_effect_flutter/actions/runs/42761367535)
  at `970d38f`: all five jobs pass. Minimum Flutter 3.32.0 and stable 3.47.9 each
  pass formatting, package/example/benchmark analysis, 63 package checks, nine
  benchmark checks, twelve independent raw-validator checks and a zero-warning
  publication dry run. Android, Windows and web build jobs pass separately.
- The published renderer passes eighteen visual contracts on each of the
  physical Xiaomi Android 10 / Impeller GLES phone, Windows/Skia, CanvasKit and
  skwasm, plus the owned Android emulator GLES target. All fifteen renderer
  source hashes match the published tag: 90 contracts across five targets.
- Separate foreground endurance retries pass on the phone (600,640 ms,
  120 disposals) and Windows (600,297 ms, 106 disposals). Both retain bounded
  tracked images and observed RSS. The current emulator also passes 600,536 ms
  and 120 disposals, with final healthy services and an empty crash buffer.
  These test iterations are not display FPS.
- Current four required mutations are detected and restored byte for byte.
  A corrected host driver rejects incomplete soak reports; eight regression
  checks and replays of seven actual saved exports cover this failure mode.
- All five hosted checks are required on `main`, bound to GitHub Actions, with
  up-to-date branches and administrator enforcement. The saved settings were
  read back and verified; force pushes and branch deletion are blocked.

See [current runtime evidence](evidence/2026-11-10/runtime-current/README.md),
[hosted check records](evidence/2026-11-10/github-ci/42761367535/checks.json)
and [the requirement audit](MILESTONE_AUDIT.md).

## Remaining work

1. Resolve the repeatability gate after targeted profiling. The full phone run
   collected 138 individually valid measurements; 34 of 46 groups meet fixed
   spread limits and twelve fail. [All data and failures](evidence/2026-11-10/performance-physical-current/README.md)
   are retained. This is not a full-matrix or 60/120-Hz performance pass.
2. Obtain human showcase, accessibility and photographic/product-background
   review. Automated contracts cover selected deterministic states.
3. Investigate background/resume separately. The phone's interrupted soak lost
   its surface and encountered a native GL-context failure after the user locked
   or switched apps. The successful foreground retry does not prove this fixed.

The original equivalent pre-change timing baseline was not obtained. Recovered
old consumer sources exhibit different optical behavior, so they do not supply
a fair historical performance comparison. Keep this deviation explicit; do not
claim a measured renderer speedup. Physical iOS/Metal, Android Vulkan, macOS and
Linux remain unverified and require separate evidence before support claims.

Earlier development ZIP/APK/Git-bundle artifacts remain in the ignored local
`.research/artifacts/` directory with their original manifests. They predate the
package rename/publication and are historical snapshots, not replacements for
the published package or its verified source tag. Local Git history begins at
the development handoff and does not reconstruct an original pre-change commit.

The deadline remains **13 November 2026**. Freeze the agreed deliverable without
adding new optical features; report unresolved qualification items explicitly.
