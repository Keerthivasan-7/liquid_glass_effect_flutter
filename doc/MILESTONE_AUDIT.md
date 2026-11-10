# Milestone requirement audit

Audit date: 2026-11-10. This tracks every work package from
[the original plan](VERIFIED_PORTABLE_RENDERER_PLAN.md). Passing source checks
alone do not complete the milestone. Unmet requirements stay visible.

| Plan requirement | Evidence / implementation | Status / remaining action |
|---|---|---|
| WP0.1 SDK floor | Exact 3.32.0 isolated checks and declared constraints | Implemented; final expanded rerun recorded separately. |
| WP0.2–4 matrix, labels, three path contracts | Compatibility/capture contract and README | Implemented; verification is scenario-specific. |
| WP0.5 original pre-change benchmark | Original Windows attempts were partial/empty and invalidated. Original consumer sources reconstructed from earlier terminal reads, with provenance/limits; paired probes demonstrate old optical defects. | Original equivalent timing baseline remains unmet. Recovered source and image probes do not replace raw timing evidence; no before/after speed claim. |
| WP0.6 inaccessible-device issues | Local issue register below | Hosted issues need canonical repository. |
| WP1.1–3 CI and SDK lanes | Workflow and exact SDK/source/check manifests | Implemented; hosted execution and publication warning remain open. |
| WP1.4–6 example, build smoke, schedule | Explicit example/benchmark analysis, separate Windows/web/Android build jobs, weekly stable checks. All build jobs record SDK identity and preserve command logs even on failure. | Workflow prepared; latest logging changes not executed. No hosted results without a repository. |
| WP1.7 required merge checks | No canonical repository supplied | External dependency. |
| WP2.1–7 bounds, rounding, unions, extremes | `capture_footprint.dart`, property tests, shader equations, affine/fractional pixel checks | Implemented/tested. Perspective is outside the declared contract. |
| WP2.8 overlay reuse, expansion, failure | Hover/press envelope, shared-crop movement, failure downgrade | Passing regression checks; background scroll captured during layer composition. |
| WP2 optional diagnostic suggestions | Union ratio, current/retained/peak bytes, retired count, generations/failures | Core fields implemented. Per-reason recapture and maximum-footprint fields were suggestions; not claimed implemented. |
| WP3 fixture backdrops 1–5 | Stripes, checker/coordinates, split fields, text/vector, live gradient, real scroll | Fixture v4; eighteen contracts, explicit fractional-ratio probe and source-image export. |
| WP3 visual assertions / shader loading | Direction/symmetry, silhouettes, sharp child, origins/affine, shared surfaces, resize/DPR/quality, stale scroll, fallback, filter | Named native/browser results; filter limited to one untransformed window-target surface. |
| WP3 uniforms | Semantic names/types/order/value manifests and runtime compile | Recorded qualification uses capture 67/filter 62 floats. Development axis precomputation uses 68/63; manifests updated and showcase compiled, with runtime checks deferred. |
| WP3 mutations / artifacts / baselines | Four required mutations plus retained-scroll defect, PNGs/logs/version | Detected and restored. Semantic tolerances replace cross-GPU equality. Human image review remains a release responsibility. |
| WP4 scenarios 1–10 / metadata | Platform records, PNGs and per-render observations; 91-second actual scrolling recording | Current v5 Windows/CanvasKit/skwasm and physical Xiaomi GLES each pass eighteen. Emulator results remain separately versioned. Vulkan, iOS and other untested targets remain Unverified. |
| WP4 ten-minute soak | Clean v4 repeat: 600,532 ms, 10,056 frames, 120 disposals; bounded images/RSS; healthy core services and empty new-crash query | Passed on project-owned emulator after disabling only its Bluetooth. Earlier Bluetooth and system_server failures remain preserved. Physical Xiaomi GLES v5 also passes a standalone 600,645-ms soak with 120 disposals; see its separate validation. No whole-phone crash-buffer claim. |
| WP4 unavailable physical backends | Explicit Unverified compatibility rows | Independent physical evidence required before broad claims. |
| WP5.1–8 harness / exports | Four-Hz HUD, bounded warm-up/window/drain, real frames, fair configs, capture metadata | Implemented; nine Dart and twelve independent-validator checks recorded before the latest renderer change. |
| WP5.9 GPU tooling | Protocol distinguishes FrameTiming from GPU/presentation/energy | No GPU cost claim. Platform traces required before such optimization conclusions. |
| WP5.10 repetitions / tolerance | Resumable 46-case matrix, raw recomputation, fixed 1.25 p50 / 1.5 p99 spread. Protocol v6 sixty-second initial and ten-second per-repetition settling. | One physical ordinary control passes three repetitions. Capture interrupted by viewport/focus change; no glass baseline/full matrix. Earlier unstable attempts retained. Thresholds unchanged; phone work deferred by user. |
| WP6 measured optimization | No speculative optical sample/quality reduction | CPU rotation-axis precomputation implemented after the user directed work forward. Sample counts and quality remain unchanged; showcase build succeeds. No measured speedup claimed; extended checks deferred. |
| WP7.1–5,7 accessibility | Exported policy, opaque path, focused tests and native/browser contracts | Implemented/checked; app supplies unavailable transparency preference. |
| WP7.6 text scaling / contrast backgrounds | Large-text/high-contrast PNGs, light/dark/mixed fields; app child-style responsibility documented | Deterministic states checked. Photographic/product and physical review unverified. |
| WP8.1 metadata | Fake URLs removed; none invented | Canonical source identity required. |
| WP8.2–4 docs / vocabulary | Three-screen showcase, four presets, comfort controls, complete integration guide, README, compatibility, progress | Development desktop/Android builds produced; final handoff reconciliation in progress. |
| WP8.5 performance manifests | Protocol v6 and ordinary-control raw/source/SDK/analysis subset archived | One qualified control, no glass/full-matrix manifest. Latest development source is different. |
| WP8.6–7 research / old spec | Exact SDK sampler audit; superseded-spec banner | Implemented. Closed issue does not imply shipped API; checked SDKs retain nearest implicit sampler/one-argument shader API. |
| WP8.8 graph | Current library-source graph: 418 nodes, 478 edges, 20 communities, including background composition and the private axis helper | Regenerated 10 November; query resolves `_anisotropyAxis` at line 18. Root/library outputs synchronized; library source hashes recorded. This is a structural library map, not runtime evidence or a shader-code graph. |
| WP8.9 archive/checklist | Earlier pub archive inspected; development source ZIP and exact artifact/source manifest prepared. Local history initialized for the `dev-handoff-2026-11-10` snapshot. | One truthful source-metadata warning and remaining release gates stay open. Local development history is not hosted CI or a verified release tag. |

## Local issue register

| ID | Dependency / gap | Closure condition |
|---|---|---|
| R1 | No hosted source repository or canonical URL. Local history initialized 10 November for the development handoff; no original pre-change history recovered. | Establish the real remote and confirm its URL/name; verified release commit/tag; hosted checks and merge rules; truthful metadata dry run. |
| R2 | Physical Android GLES / Vulkan | Xiaomi Android 10 GLES passes all 18 v5 visuals. Standalone ten-minute endurance also passes; timing remains separate. Qualify Vulkan independently. |
| R3 | Physical iOS Metal / filter overlap | Physical capture/scroll/overlap plus separate overlapping-filter evidence. Simulator/closed issue insufficient. |
| R4 | macOS / Linux | Named runtime runs if entering the verified set. |
| R5 | Missing equivalent original timing baseline | Original consumer code recovered with documented provenance; paired image probes show original defects. Preserve the timing deviation; recovered code is not an original timing result. |
| R6 | Repeatable matrix / latest harness | One physical ordinary control accepted; capture interrupted. Full matrix and newer portrait/axis source measurements remain deferred. |
| R7 | Photographic/product accessibility | Intended foreground styles, large text, focus and opaque states reviewed on intended devices. |

A narrower verified platform matrix is allowed by the plan. It does not excuse
missing raw performance evidence or inaccurate release claims. The milestone
exit gate remains open while required evidence and source identity are missing.
