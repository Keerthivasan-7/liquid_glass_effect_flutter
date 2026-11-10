# Verified Portable Renderer execution record

Delivery steering: target **13 November 2026**. Extended testing has stopped at
the user's request; see [the four-day delivery plan](FOUR_DAY_DELIVERY.md).
The latest development change moves constant anisotropy rotation math to the
CPU. It updates the capture/filter uniform layouts to 68/63 floats and has not
been covered by the earlier runtime evidence below. No measured speedup is claimed.

Updated: 2026-11-10. The milestone remains in progress. Evidence applies to its
recorded source snapshot, SDK, backend and scenarios. See
[MILESTONE_AUDIT.md](MILESTONE_AUDIT.md) for the requirement audit.

| Work package | Implemented and checked | Remaining gate |
|---|---|---|
| WP0 support contract | Separate capture, Impeller filter and fallback contracts; named backend evidence and explicit unverified targets. | Original pre-change performance baseline was not obtained. No before/after speed claim is permitted. |
| WP1 SDK checks | Recorded minimum 3.32.0 and stable 3.47.9 checks cover formatting, analysis, 55 package and nine benchmark checks. All 46 source-snapshot entries matched the recorded check snapshot; the later axis-precomputation and showcase changes postdate those checks. The publication dry run reports the truthful missing-source-metadata warning. CI/scheduled/build smoke workflows implemented. | Hosted CI/merge protection, real-source-metadata warning and final-source qualification. |
| WP2 capture footprint | Conservative optical envelope; actual-image dimensions; affine mapping; interaction envelope; guarded retirement; scope-anchored fractional texel lattice. Regression fails before grid alignment and passes after. | Platform qualifications retain their explicit limits. |
| WP3 visual contracts | Eighteen shared contracts, semantic uniform/value manifests, PNG/runtime exports. Four required mutations and a retained-scroll mutation detected and restored. | Physical-device review remains separate. |
| WP4 runtime qualification | Fixture v4 passes all eighteen contracts on Windows, CanvasKit, skwasm and fresh Android GLES. Clean Android v4 repeat completes 600,532 ms, 10,056 frames and 120 disposals with bounded retention. Native PixelCopy fixture v5 additionally passes all eighteen visual contracts. Scrolling video saved. | The clean v4 repeat has healthy core services and no new crash entries after Bluetooth was disabled only in the project-owned AVD. Earlier failures remain preserved. Physical Xiaomi GLES v5 passes all eighteen visuals and a standalone 600,645-ms endurance run with 120 disposals. Vulkan/iOS and other untested targets remain separate. |
| WP5 benchmark | Raw timestamped timings, fair cases, resumable 46-case matrix and twelve independent validator checks. Protocol v6 adds sixty-second initial settling, ten seconds per repetition, memory preflight, authenticated app reuse and focus/viewport invalidation. One physical ordinary-control group has three independently accepted repetitions. | Prior unstable attempts are preserved. The capture group was interrupted and invalidated. The ordinary control predates the portrait safeguards and latest optimization; no qualified glass baseline or full matrix. Phone work deferred by user. |
| WP6 optimization | CPU rotation-axis precomputation now reuses constant values across sampling and highlights; showcase build succeeds. Hover/press capture reuse has a prior count-based check. | Repeatable baseline/profiling must justify further optimization; no FPS/GPU improvement claimed. |
| WP7 accessibility | Explicit transparency/motion/contrast; opaque treatment; inherited contrast; keyboard/accessibility focus and child actions. Seven focused checks plus native/browser contracts. | Physical-device and photographic/product-background review unverified. |
| WP8 release docs | Contracts, SDK sampler audit, reference comparison and complete integration guide. Showcase has three functional screens, four presets and comfort previews; desktop/Android builds produced. Current library graph: 418 nodes/478 edges/20 communities. Development source bundle: 192 files, with source/artifact hashes and separate offline Git bundle. Earlier pub archive inspection applies to its recorded snapshot. | Final pub-package qualification, canonical repository and verified release commit/tag; one metadata warning. Current builds and source ZIP do not replace runtime qualification or a pub dry run. |

## Four-day delivery

Target: **13 November 2026**. Renderer axis precomputation and the showcase
rewrite are implemented. Materials, Controls and Comfort now open distinct
screens; presets, session favorites, fine adjustments/reset and accessibility
previews work through actual app state. Diagnostics are isolated from the page
build. A settings-navigation edge case and reduced-motion expansion were
included in the final Android build. See the [integration guide](INTEGRATION_GUIDE.md)
and [showcase instructions](../example/README.md). Extended tests and phone
installation remain deferred by user direction.

Release preparation also refreshed the library architecture map after the
axis-helper change. Future CI now explicitly analyzes example/benchmark apps
and preserves SDK/dependency/build logs for all platform build jobs, including
failures. These workflow changes have not run; no hosted CI result is claimed.

## Evidence locations

- [Windows fixture v5](evidence/2026-11-09/windows-v5/runtime.json).
- [CanvasKit release v5](evidence/2026-11-09/web-canvaskit-v5/runtime.json).
- [skwasm release v5](evidence/2026-11-09/web-skwasm-v5/runtime.json).
- [Android v4 checks](evidence/2026-11-09/android-v4-calibrated/contracts/runtime.json),
  [soak and system caveat](evidence/2026-11-09/android-v4-calibrated/validation.json),
  [recorded contracts](evidence/2026-11-09/android-v4-recorded-contracts/runtime.json)
  and [scrolling recording](evidence/2026-11-09/android-v4-recorded-contracts/scrolling.mp4).
- [Clean v4 endurance repeat](evidence/2026-11-09/android-v4-bluetooth-off/validation.json)
  and [native PixelCopy v5 visual contracts](evidence/2026-11-09/android-native-v5-centers-contracts/runtime.json).
- [Physical Xiaomi Android 10 / GLES: all eighteen aligned v5 contracts](evidence/2026-11-09/physical-android/aligned-contracts/runtime.json),
  [successful driver](evidence/2026-11-09/physical-android/aligned-contracts/result.json)
  and [APK/source identity](evidence/2026-11-09/physical-android/qualification-aligned-build.json).
- [Physical GLES ten-minute endurance](evidence/2026-11-09/physical-android/aligned-soak/validation.json): 5,460 test iterations, 120 disposals, 593 changed signatures/601 samples; RSS after warm-up 152–190 MB. These iterations are not display FPS.
- [Required mutations](evidence/2026-11-09/mutations/results.json)
  and [retained-scroll mutation](evidence/2026-11-09/mutations/retained-scroll.json).
- [Minimum SDK](evidence/2026-11-09/sdk-minimum/checks.json)
  and [stable SDK](evidence/2026-11-09/sdk-stable/checks.json).

Raw evidence is excluded from the pub archive. Repository readers can inspect
PNGs, logs, runtime observations and source hashes.

## Identity and failed attempts

Installed SDK: Flutter 3.44.1, framework 924134a44c, Dart 3.12.1.
Minimum: 3.32.0, framework be698c48a6750c8cb8e61c740ca9991bb947aba2, Dart 3.8.0.
Stable: 3.47.9, framework c197ca5199e9ee5661e865596c9c07294dfab51c, Dart 3.13.7.
Official SDKs and isolated validation copies are in ignored `.research/`.

The user confirmed on 2026-11-09 that no repository existed. Local Git history
was initialized on 10 November for the development handoff, with the snapshot
named `dev-handoff-2026-11-10`. This starts from the current development source;
it does not recover an original pre-change revision. The user subsequently
created `https://github.com/Keerthivasan-7/liquid_glass_effect`, now connected as
`origin`. Package source/issue links use this real URL. The earlier dry run's
missing-source warning is historical; the dry run has not been repeated.
Hosted CI, branch protection and a verified release tag remain open. The initial
upload uses a CI-skip instruction to respect the user's testing deferral.

Initial Windows benchmarks were timed-out partial/empty runs; all are preserved
and invalidated. A minimized Windows soak was invalidated. Filter-coordinate
and release semantics failures were corrected and rerun. Immediate picture
disposal reproduced a skwasm retained-scene failure; two-frame retirement fixes
it on both tested SDKs. Real scrolling exposed stale captures when only a
background descendant repainted; composition-time capture fixes that regression.

The 2026-11-06 soak passed on its earlier source. A November 9 run finished app
checks but Android system_server died, invalidating that environment. A fresh
AVD exposed a fractional texel-grid issue and an antialiased calibration seam;
both were fixed without relaxing tolerances. Final fixture-v4 renderer checks
and a ten-minute soak pass; an unrelated Bluetooth hardware crash remains an
explicit system caveat. Its package service stayed healthy and RSS after the
first minute stayed between 215,105,536 and 234,012,672 bytes. Bluetooth was then
disabled only in the disposable AVD before performance measurement.
The subsequent clean v4 repeat passed with no new crash-buffer entries and
healthy core services. The v5 native-reader suite initially exposed logical-edge
sampling; mapping to logical pixel centers resolves all three failures without
changing any optical tolerance. A physical Android 10 attempt stalled in engine
offscreen readback; native PixelCopy qualification remains separate. The user
confirmed the earlier USB removal was intentional.
No record is retroactively attributed to a different snapshot.
Scope RGBA estimates are not GPU counters. Builds are not runtime evidence.
Physical Xiaomi Android 10 GLES visuals pass all eighteen aligned v5 contracts;
its standalone endurance passes 600,645 ms and 120 disposals; timing evidence remains separate. Physical iOS,
Vulkan, other Android devices, macOS and Linux remain unverified.
