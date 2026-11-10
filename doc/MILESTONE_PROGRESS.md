# Verified Portable Renderer execution record

Publication preparation (10 November): the user requested pub.dev publication
and proposed `liquid_glass_effect_flutter` because `liquid_glass_effect` is taken.
The proposed name returned 404 from the pub.dev package API. Current imports,
public entry point, shader asset keys and example dependencies now use the new
name. Actual showcase screenshots and a package-focused README are included.
Version `0.1.0-dev.1` is now published on
[pub.dev](https://pub.dev/packages/liquid_glass_effect_flutter), from source
tag `v0.1.0-dev.1` / commit `954ea73`. The final dry run returned zero warnings;
the downloaded registry archive matches its checksum and all 21 prepared-file
hashes. See [the publication record](evidence/2026-11-10/pub-publication.json).
The verification milestone and runtime/performance gates below remain open.
Historical evidence is unchanged.

Delivery steering: target **13 November 2026**. On 10 November the user requested
all tests and made the phone available for the full matrix, superseding the
earlier test deferral. See [the four-day delivery plan](FOUR_DAY_DELIVERY.md).
Current runtime results include CPU rotation-axis precomputation and the 68/63
capture/filter uniform layouts. No measured speedup is claimed.

Updated: 2026-11-10. The milestone remains in progress. Evidence applies to its
recorded source snapshot, SDK, backend and scenarios. See
[MILESTONE_AUDIT.md](MILESTONE_AUDIT.md) for the requirement audit.

| Work package | Implemented and checked | Remaining gate |
|---|---|---|
| WP0 support contract | Separate capture, Impeller filter and fallback contracts; named backend evidence and explicit unverified targets. | Original pre-change performance baseline was not obtained. No before/after speed claim is permitted. |
| WP1 SDK checks | Hosted CI on `b417012` passes all five jobs: exact minimum 3.32.0 and stable 3.47.9 lanes plus Android, web and Windows builds. Each package lane passes formatting, all three analyses, 63 package checks, ten benchmark checks, seventeen independent-validator checks and a zero-warning dry run. All five checks are required on `main`, strict and enforced for administrators. | Keep future changes passing these checks. |
| WP2 capture footprint | Conservative optical envelope; actual-image dimensions; affine mapping; interaction envelope; guarded retirement; scope-anchored fractional texel lattice. Regression fails before grid alignment and passes after. | Platform qualifications retain their explicit limits. |
| WP3 visual contracts | Eighteen shared contracts, semantic uniform/value manifests and PNG/runtime exports. All four required mutations detected and source restored on the current renderer. Prior retained-scroll mutation remains recorded. | Human image and product-background review remains separate. |
| WP4 runtime qualification | Current published renderer passes eighteen v5 contracts on each of physical Xiaomi GLES, Android emulator GLES, Windows/Skia, CanvasKit and skwasm: 90 contracts, 215 observations. Current foreground ten-minute endurance passes on the phone (600,640 ms, 120 disposals), Windows (600,297 ms, 106 disposals) and emulator (600,536 ms, 120 disposals). Final emulator crash buffer empty and package/activity services present. | Interrupted phone and timed-out Windows attempts remain failed. Background/resume, Vulkan/iOS and other untested targets remain unverified. |
| WP5 benchmark | V6 baseline: 46 groups / 138 raw exports, 34 accepted and twelve rejected, unchanged. Profiling identifies periodic display builds; v7 freezes the active display. Four selected v7 phone groups each pass three repetitions, with independent raw/hash validation. | Forty-two v7 groups remain unmeasured. Fixed spread limits and v6 failures are unchanged; no full-matrix or smooth-60-Hz pass. Phone released after the authorized focused run. |
| WP6 optimization | CPU rotation-axis precomputation now reuses constant values across sampling and highlights; showcase build succeeds. Hover/press capture reuse has a prior count-based check. | Repeatable baseline/profiling must justify further optimization; no FPS/GPU improvement claimed. |
| WP7 accessibility | Explicit policies and existing phone/native/browser contracts. New Windows photographic opaque-reading fixture passes twelve cases at 1×/2×/3× with native text, scrolling, contrast, keyboard actions and semantics; desktop-density failure reproduced and corrected. | Human physical-device, screen-reader and intended product-layout review unverified. New photo fixture has Windows evidence only. |
| WP8 release docs | Contracts, SDK sampler audit, reference comparison and integration guide. Three-screen showcase, four presets and comfort previews. Current library graph: 419 nodes/479 edges/21 communities. Published prerelease, canonical repository, source tag, required merge checks and verified registry checksum recorded. | Finish current performance manifest and remaining review; reconcile final delivery notes. Publication is separate from milestone completion. |

## Four-day delivery

Target: **13 November 2026**. Renderer axis precomputation and the showcase
rewrite are implemented. Materials, Controls and Comfort now open distinct
screens; presets, session favorites, fine adjustments/reset and accessibility
previews work through actual app state. Diagnostics are isolated from the page
build. A settings-navigation edge case and reduced-motion expansion were
included in the final Android build. See the [integration guide](INTEGRATION_GUIDE.md)
and [showcase instructions](../example/README.md). The full phone measurement
phase is finished and the phone released; twelve groups remain unstable.

Release preparation also refreshed the library architecture map after the
axis-helper change. Hosted CI explicitly analyzes example/benchmark apps
and preserves SDK/dependency/build logs for all platform build jobs, including
failures. All five jobs passed in
[run 42761367535](https://github.com/Keerthivasan-7/liquid_glass_effect_flutter/actions/runs/42761367535),
source `970d38f`. An initial latest-stable archive check exposed an SDK migration
rewriting analysis excludes; the configuration was corrected before both
subsequent complete CI runs passed.

## Current-source evidence — 10 November

- [Runtime summary and source hashes](evidence/2026-11-10/runtime-current/source-and-results.json):
  all fifteen renderer files match published source `954ea73`.
- [Current runtime records and retained failures](evidence/2026-11-10/runtime-current/README.md).
- [Hosted SDK checks and platform build logs](evidence/2026-11-10/github-ci/42761367535/artifacts.json).
- [Required merge-check settings](evidence/2026-11-10/github-ci/required-checks.json):
  all five named checks bound to GitHub Actions, up-to-date branches required,
  administrator enforcement enabled, force pushes and branch deletion blocked.
- [Minimum SDK clean checkout](evidence/2026-11-10/sdk-minimum/clean-checkout/checks.json)
  and [stable clean checkout](evidence/2026-11-10/sdk-stable/clean-checkout/checks.json).
  These local checks at `bc87b63` contain 55 package checks; hosted `970d38f`
  additionally covers eight host-driver validation regressions, for 63 total.
- [Current four required mutations](evidence/2026-11-10/mutations-current/results.json).
- [Report-validator replay against seven real exports](evidence/2026-11-10/native-report-regression.json).
  The old Windows driver returned zero for an incomplete timed-out soak. The
  corrected driver preserves evidence and rejects that report. The successful
  retry passed the corrected driver.
- [Full current phone performance report](evidence/2026-11-10/performance-physical-current/README.md):
  46 groups / 138 measurements, 34 qualified groups, twelve unstable. Raw files
  are unchanged copies and all independent statistics/hash checks match.
- [Protocol-v7 observer fix and bounded traces](evidence/2026-11-10/measurement-display/README.md).
- [Four focused v7 phone groups](evidence/2026-11-10/performance-physical-v7-focused/README.md):
  twelve valid measurements, all fixed group-spread checks passed. This is four
  selected cases only; forty-two v7 cases remain unmeasured.
- [Photographic accessibility fixture](evidence/2026-11-10/photo-accessibility/README.md):
  twelve Windows cases, twenty-four native images; original 40-pixel button
  failure retained and corrected without altering the production renderer.
- [Current hosted CI](evidence/2026-11-10/github-ci/42791541004/checks.json):
  both SDK lanes and all three platform builds pass at `b417012`.

The initial current phone soak lost its rendering surface after the user locked
or switched apps, followed by a native GL-context crash. It remains a failed
attempt. The completed foreground retry does not establish background/resume
reliability. Current foreground results and fixed-window benchmark results have
separate acceptance conditions.

## Historical evidence locations — earlier source snapshots

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
created `https://github.com/Keerthivasan-7/liquid_glass_effect_flutter`, now connected as
`origin`. Package source/issue links use this real URL. The earlier dry run's
missing-source warning is historical; current clean-checkout and hosted dry
runs have zero warnings. The source tag, hosted CI and required merge checks
are verified. Only the initial uploads used a CI-skip instruction;
the user subsequently authorized the complete suites.

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
