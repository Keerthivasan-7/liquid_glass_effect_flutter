# Milestone requirement audit

Audit date: 2026-11-10. This tracks every work package from
[the original plan](VERIFIED_PORTABLE_RENDERER_PLAN.md). Passing source checks
alone do not complete the milestone. Unmet requirements stay visible.

| Plan requirement | Evidence / implementation | Status / remaining action |
|---|---|---|
| WP0.1 SDK floor | Exact 3.32.0 isolated clean-checkout checks and declared constraints; hosted 3.32.0 lane passes all 63 package checks | Passed for current checked source `970d38f`. |
| WP0.2–4 matrix, labels, three path contracts | Compatibility/capture contract and README | Implemented; verification is scenario-specific. |
| WP0.5 original pre-change benchmark | Original Windows attempts were partial/empty and invalidated. Original consumer sources reconstructed from earlier terminal reads, with provenance/limits; paired probes demonstrate old optical defects. | Original equivalent timing baseline remains unmet. Recovered source and image probes do not replace raw timing evidence; no before/after speed claim. |
| WP0.6 inaccessible-device issues | Local issues R2–R4 below track unavailable Vulkan, iOS/Metal and optional macOS/Linux hardware | Recorded; keep the corresponding targets unverified until evidence is obtained. |
| WP1.1–3 CI and SDK lanes | Hosted run `42761367535`, source `970d38f`: exact minimum 3.32.0 and stable 3.47.9. Both lanes pass 63 package, nine benchmark and twelve independent validator checks, format, all three analyses and zero-warning dry runs. | Passed; exact SDK identities and logs preserved. Initial SDK-migration/archive failure retained and corrected. |
| WP1.4–6 example, build smoke, schedule | Explicit example/benchmark analysis, Windows/web/Android builds, weekly stable schedule. All three hosted build jobs pass and preserve SDK/build logs. | Implemented and hosted builds passed; future scheduled results remain prospective. |
| WP1.7 required merge checks | All five successful job contexts required on `main`, bound to GitHub Actions app 15368; strict up-to-date checks and administrator enforcement enabled | Configured and verified by API readback; [settings record](evidence/2026-11-10/github-ci/required-checks.json). No extra reviewer requirement added. |
| WP2.1–7 bounds, rounding, unions, extremes | `capture_footprint.dart`, property tests, shader equations, affine/fractional pixel checks | Implemented/tested. Perspective is outside the declared contract. |
| WP2.8 overlay reuse, expansion, failure | Hover/press envelope, shared-crop movement, failure downgrade | Passing regression checks; background scroll captured during layer composition. |
| WP2 optional diagnostic suggestions | Union ratio, current/retained/peak bytes, retired count, generations/failures | Core fields implemented. Per-reason recapture and maximum-footprint fields were suggestions; not claimed implemented. |
| WP3 fixture backdrops 1–5 | Stripes, checker/coordinates, split fields, text/vector, live gradient, real scroll | Current fixture v5; eighteen contracts per target, explicit fractional-ratio probe, native Android PixelCopy and source-image export. |
| WP3 visual assertions / shader loading | Direction/symmetry, silhouettes, sharp child, origins/affine, shared surfaces, resize/DPR/quality, stale scroll, fallback, filter | Named native/browser results; filter limited to one untransformed window-target surface. |
| WP3 uniforms | Semantic names/types/order/value manifests and runtime compile | Current capture 68/filter 63 floats; package checks and current native/browser runtime qualification pass. |
| WP3 mutations / artifacts / baselines | All four required mutations detected on current renderer and restored byte for byte; prior retained-scroll defect recorded | Passed mutation checks. Semantic tolerances replace cross-GPU equality. Human image review remains open. |
| WP4 scenarios 1–10 / metadata | Current platform records, 90 contracts and 215 observations; prior actual scrolling recording | Current v5 Windows/CanvasKit/skwasm, physical Xiaomi GLES and owned Android emulator GLES each pass eighteen; fifteen renderer files match the published source. Vulkan, iOS and other untested targets remain Unverified. |
| WP4 ten-minute soak | Current phone: 600,640 ms, 601 samples, 120 disposals; Windows: 600,297 ms, 525 samples, 106 disposals; emulator: 600,536 ms, 601 samples, 120 disposals; bounded images/RSS | All three foreground runs pass; final emulator package/activity services present and crash buffer empty. Interrupted phone surface/GL-context failure and timed-out Windows attempt remain failures. Corrected host driver rejects incomplete exports; eight regression checks and seven real-export replays pass. No background/resume or whole-phone crash-buffer claim. |
| WP4 unavailable physical backends | Explicit Unverified compatibility rows | Independent physical evidence required before broad claims. |
| WP5.1–8 harness / exports | Four-Hz HUD, bounded warm-up/window/drain, real frames, fair configs, capture metadata | Implemented; nine Dart and twelve independent-validator checks pass on both current hosted SDK lanes. |
| WP5.9 GPU tooling | Protocol distinguishes FrameTiming from GPU/presentation/energy | No GPU cost claim. Platform traces required before such optimization conclusions. |
| WP5.10 repetitions / tolerance | Full current phone matrix: 46 groups / 138 individually valid raw runs; independent recomputation and unchanged 1.25 p50 / 1.5 p99 gates | Measurement phase complete; 34 groups qualify and twelve fail repeatability (eleven build-p50, one blur-10-animated raster/total-span-p99). All failures preserved; runner exits one. Physical-device host memory gate explicitly zero MiB. Full matrix is not qualified. |
| WP6 measured optimization | CPU rotation-axis precomputation; no optical sample/quality reduction | Current visual checks pass. Equivalent pre-change timing/profile comparison remains unmet; no measured speedup claimed. Complete the baseline before considering further optimization. |
| WP7.1–5,7 accessibility | Exported policy, opaque path, focused tests and native/browser contracts | Implemented/checked; app supplies unavailable transparency preference. |
| WP7.6 text scaling / contrast backgrounds | Large-text/high-contrast PNGs, light/dark/mixed fields; app child-style responsibility documented | Deterministic states checked. Photographic/product and physical review unverified. |
| WP8.1 metadata | Canonical repository now `Keerthivasan-7/liquid_glass_effect_flutter`; origin updated after GitHub reported the rename. Real package source/issue links added. | First prerelease published; clean-source dry run has zero warnings. The first archive's former repository URL redirects to the renamed source. |
| WP8.2–4 docs / vocabulary | Three-screen showcase, four presets, comfort controls, complete integration guide, README, compatibility, progress | Development desktop/Android builds produced; final handoff reconciliation in progress. |
| WP8.5 performance manifests | All 138 unchanged raw files plus source/SDK/APK identity, metadata, per-attempt statistics and final independent analysis preserved | [Full current report](evidence/2026-11-10/performance-physical-current/README.md) includes the twelve unstable groups. Curation complete; repeatability remains R6. |
| WP8.6–7 research / old spec | Exact SDK sampler audit; superseded-spec banner | Implemented. Closed issue does not imply shipped API; checked SDKs retain nearest implicit sampler/one-argument shader API. |
| WP8.8 graph | Current library-source graph: 419 nodes, 479 edges, 21 communities, including the new public entry point, background composition and private axis helper | Regenerated after the publication rename on 10 November. Root/library outputs synchronized; library source hashes recorded. This is a structural library map, not runtime evidence or a shader-code graph. |
| WP8.9 archive/checklist | Published prerelease archive: 628,400 bytes / 181 files; checksum and 21 prepared-file hashes verified, private exclusions confirmed. Source `954ea73` tagged `v0.1.0-dev.1`. | Current runtime, hosted checks and required merge checks pass within their named scope. Performance and human review remain open; publication does not complete the milestone. |

## Local issue register

| ID | Dependency / gap | Closure condition |
|---|---|---|
| R1 | Canonical repository, first prerelease, exact source tag, current runtime, two successful complete hosted CI runs and verified required merge checks recorded. No original pre-change history recovered. | Source-hosting/CI setup complete. Initial upload skipped CI; subsequent commits ran all five jobs. Historical timing-baseline gap remains R5. |
| R2 | Physical Android GLES / Vulkan | Current Xiaomi Android 10 GLES passes 18 v5 visuals and ten-minute foreground endurance. Full phone measurement phase complete, with repeatability failures tracked separately. Qualify Vulkan independently. |
| R3 | Physical iOS Metal / filter overlap | Physical capture/scroll/overlap plus separate overlapping-filter evidence. Simulator/closed issue insufficient. |
| R4 | macOS / Linux | Named runtime runs if entering the verified set. |
| R5 | Missing equivalent original timing baseline | Original consumer code recovered with documented provenance; paired image probes show original defects. Preserve the timing deviation; recovered code is not an original timing result. |
| R6 | Repeatable matrix / latest harness | Current phone matrix measured all 46 groups; 34 meet fixed gates and twelve do not. Preserve all attempts and obtain targeted profiling before changing source/protocol; no threshold relaxation or best-run selection. |
| R7 | Photographic/product accessibility | Intended foreground styles, large text, focus and opaque states reviewed on intended devices. |
| R8 | Interrupted surface / background-resume | Preserve the current phone native GL-context crash after the user locked/switched apps. Foreground retry passes, but background/resume remains unverified and requires separate investigation. |

A narrower verified platform matrix is allowed by the plan. It does not excuse
missing raw performance evidence or inaccurate release claims. The milestone
exit gate remains open while required evidence and source identity are missing.
