# Verified Portable Renderer — implementation plan

Status: implementation in progress · Updated: 2026-11-09 · Baseline: 0.1.0-dev.1

Current execution evidence and remaining gates are recorded in
[MILESTONE_PROGRESS.md](MILESTONE_PROGRESS.md). The additional Flutter/web source
comparison is in [REFERENCE_COMPARISON.md](REFERENCE_COMPARISON.md).
The requirement-by-requirement audit, including the missing original
pre-change timing baseline, is in [MILESTONE_AUDIT.md](MILESTONE_AUDIT.md).

## 1. Milestone outcome

Make the existing rendering system dependable and measurable across the
platforms the package intends to support. A developer should be able to tell
which renderer is active, what visual behavior to expect, what the fallback
does, and what performance evidence supports the compatibility claim.

The milestone is complete when:

1. The declared minimum Flutter SDK and the current stable SDK pass automated
   package checks.
2. Capture bounds are proven to contain every sample the shader can request,
   including high-roughness, high-scatter, anisotropic, and ultra-quality cases.
3. Deterministic visual checks prove displacement direction, clipping,
   foreground sharpness, crop-origin mapping, resize behavior, and fallback
   output on supported renderers.
4. Each platform advertised as capture-capable has a recorded runtime result;
   each other platform is explicitly labeled fallback-only, unverified, or
   unsupported.
5. Performance results can be repeated from raw data and include device,
   renderer, resolution, refresh rate, capture size, and frame timing details.
6. Accessibility and documentation describe the behavior that was actually
   validated.

This is a verification and hardening milestone. It does not add new optical
features.

## 2. Product and renderer contract

### Product promise

Describe the package as a portable, screen-space optical material for Flutter.
Use Apple’s public design guidance to inform hierarchy and material behavior,
but do not promise parity with Apple’s private compositor or shader.

### Render paths

| Path | Role in this milestone | Required behavior |
|---|---|---|
| Capture | Primary portable refraction path inside LiquidGlassScope or LiquidGlassScene | Samples only the declared content plane; reports failures; preserves sharp foreground content; obeys bounded sample regions. |
| Filter | Impeller-only path, available when explicitly selected or when no capture scope applies | Is capability-gated; reports its path; is tested independently from capture; does not imply cross-platform support. |
| Fallback | Universal degraded path | Remains readable, clipped to the requested shape, and usable when shader loading, capture, or backend capability fails. Diagnostics must report fallback. |

### Platform contract to decide at WP0

Use this proposed matrix as the default execution target. The maintainer may
remove a platform from the supported set, but must not call an untested platform
supported merely because it compiles.

| Platform/backend | Capture verification target | Filter verification target | If the target cannot be verified |
|---|---|---|---|
| Windows / Skia | Profile runtime and visual fixture | Not applicable | Mark capture unverified; retain fallback. |
| Android / Impeller OpenGL ES | Emulator plus physical device if available | Runtime capability check and one explicit filter smoke test | Keep emulator-only evidence clearly labeled; do not imply physical-device coverage. |
| Android / Impeller Vulkan | At least one physical or representative emulator run | Runtime capability check and one explicit filter smoke test | Mark Vulkan unverified separately from OpenGL ES. |
| iOS / Impeller Metal | Physical device capture run, including scrolling and overlap | Separate filter-path test for overlapping surfaces | If physical hardware is unavailable, keep iOS capture unverified and do not make a broad iOS claim. |
| Web / CanvasKit | Release runtime in a supported browser | Not applicable | Mark CanvasKit fallback-only or unverified. |
| Web / skwasm | Release runtime in a supported browser with required browser features | Not applicable | Mark skwasm fallback-only or unverified. |
| macOS / Linux | Run only if the project chooses to advertise them in this release | Capability-gated | Keep them explicitly unverified until runtime evidence exists. |

The filter path is not a substitute for capture qualification. Flutter’s
ImageFilter.shader API is Impeller-only, while custom canvas fragment shaders
are supported by both Skia and Impeller. Keep those claims separate in the
compatibility documentation.

## 3. Baseline findings that shape the work

These findings come from the current source and project documentation:

- LiquidGlassScene separates content from functional glass, and
  LiquidGlassScope captures the background before painting the overlay.
- _RenderLiquidGlassScope calls OffsetLayer.toImageSync for a crop derived from
  active capture clients. The scope uses one rectangular bounding box for all
  surfaces, so distant controls can include a large empty region.
- Capture-client padding currently adds maxDisplacement, blurSigma, and a small
  margin. The shader’s effective scatter radius also depends on roughness and
  scattering, and its tap offsets are stretched by anisotropy. Those formulas
  need one explicit, tested sample-footprint contract.
- The filter and capture shaders duplicate most of the optical implementation
  and use different uniform layouts. Dart binds both layouts by numeric slot.
- Existing contract tests check declaration counts and selected shader text;
  they do not prove every Dart slot maps to the correct named uniform or verify
  rendered pixels.
- Current recorded evidence includes a Windows capture smoke test and Android
  emulator validation on Impeller OpenGL ES. Browser runtime, physical iOS,
  physical Android, macOS, Linux, GPU timing, and advanced-renderer goldens are
  still listed as unverified in the project docs.
- The benchmark uses a moving background and refreshes its display while
  sampling. It does not export raw results or capture all the metadata required
  by the performance protocol.
- Package homepage, repository, and issue URLs still use example.com paths.
- The local graph report predates LiquidGlassScene, LiquidGlassScope, and
  LiquidGlassGroup. Regenerate it after implementation source changes; do not
  use that old snapshot as a current architecture map.

Flutter documents that OffsetLayer.toImageSync returns an image handle before
rasterization completes on the raster thread. It also produces uncompressed
RGBA image data. Therefore, the plan treats repeated raster work and peak image
memory as measured costs; it does not assume a synchronous CPU readback or a
UI-thread stall without profiling evidence.

## 4. Explicit non-goals

- No new Fresnel, dispersion, thin-film, environment, or lighting parameters.
- No group contour union, metaball blending, or morph animation.
- No Flutter GPU dependency or native iOS renderer in the core package.
- No claim that a build proves runtime compatibility.
- No FPS claim from one device, one run, or a Dart stopwatch.
- No exact cross-device golden equality for GPU output. Use renderer-specific
  baselines and tolerant visual assertions where rasterization differs.
- No macOS, Linux, browser, or physical-device claim without runtime evidence.

## 5. Work packages and sequencing

### WP0 — Lock the support contract and measurement baseline

**Purpose:** prevent implementation and documentation from using different
definitions of “portable.”

Tasks:

1. Confirm the SDK floor from pubspec.yaml. The current declaration is Flutter
   3.32 or newer; preserve it only if CI passes on that exact floor.
2. Confirm the target platform matrix in Section 2. Record the device or runner
   required for each platform, its OS version, Flutter revision, and renderer.
3. Define support labels used in docs: Verified, Verified with fallback,
   Unverified, and Unsupported. “Expected” is not a verification status.
4. Define the exact rendering contracts for each path:
   - Capture samples the content plane only and never captures its glass overlay.
   - Filter uses the compositor backdrop only when supported by Impeller.
   - Fallback reports its path and keeps foreground children sharp.
5. Save one baseline benchmark run for each currently executable target before
   changing capture math or shader code.
6. Record an issue for any device or browser that cannot be accessed. Keep the
   corresponding platform unverified until evidence is collected.

Deliverables:

- A reviewed support matrix in doc/COMPATIBILITY.md.
- A benchmark run manifest with device, SDK, renderer, resolution, DPR, and Hz.
- A short written renderer contract linked from the README.

Exit gate: no platform has a “Yes” or “supported” claim without a named runtime
result or a clearly documented fallback-only status.

### WP1 — Add continuous integration for the declared SDK range

**Purpose:** catch package regressions before device qualification.

Tasks:

1. Add a CI workflow after the canonical source repository is confirmed. The
   pubspec currently contains placeholder repository metadata, so do not wire a
   workflow to a fictitious remote.
2. Add two SDK lanes:
   - The exact minimum Flutter version declared in pubspec.yaml.
   - The newest stable Flutter version available when the workflow runs.
3. On both lanes run dependency resolution, formatting check, analyzer, package
   tests, and publish dry-run. Preserve command output as CI artifacts on
   failure.
4. Analyze and resolve dependencies in the example app. Ensure the root package
   and example use compatible SDK constraints.
5. Add platform build smoke jobs only where the runner can provide the needed
   toolchain. Keep build smoke jobs separate from device runtime tests.
6. Add a scheduled latest-stable job so Flutter changes are detected even when
   no code is submitted.
7. Make CI failures block merging when the project repository is established.

Suggested checks:

- dart format --output=none --set-exit-if-changed .
- flutter analyze
- flutter test
- flutter pub publish --dry-run
- Example dependency resolution, analysis, and a build for the supported CI
  target.

Acceptance criteria:

- Both declared-minimum and latest-stable lanes pass from a clean checkout.
- CI reports the exact Flutter and Dart revisions in its logs.
- A failed shader build or missing package asset fails the job visibly.
- No generated build, graph, or benchmark result artifact is included in the
  package archive.

### WP2 — Make the capture sample footprint explicit and testable

**Purpose:** guarantee that each shader lookup is backed by pixels in the
captured image and avoid boundary clamping changing the requested sample.

Tasks:

1. Document the complete sampling envelope in one place. Include:
   - Refraction displacement, including maxDisplacement.
   - Blur radius and roughness/scattering contribution to scatterRadius.
   - The actual stencil reach for performance, balanced, and ultra quality.
   - Anisotropic stretching and rotation of each stencil offset.
   - Red/blue dispersion and legacy chromatic offset.
   - The reflection offset and reflection scatter radius.
2. Add a package-private Dart helper that computes a conservative logical-pixel
   sample footprint from LiquidGlassConfig, shape size, and quality. Keep the
   helper’s inputs and units explicit.
3. Use that helper in captureBoundsIn instead of independently approximating
   required padding there.
4. Audit soft_clamp and clamp_uv against the crop-local image dimensions. Ensure
   they clamp to pixels that actually exist in the captured texture, not an
   imagined full-scope texture.
5. Account for pixelRatio and qualityScale when converting logical bounds to
   captured pixels. Test fractional crop bounds and non-integer DPR values.
6. Add tests for minimum and maximum legal configuration values, including
   high roughness, scattering, anisotropy, ultra quality, and maximum
   displacement.
7. Add cases with two glass surfaces close together and at opposite corners.
   Confirm the resulting crop contains both surfaces plus the full sampling
   envelope; record the crop-to-scope area ratio.
8. Preserve the rule that overlay-only movement inside the existing crop does
   not force a new capture. Movement outside the crop must request a new capture
   before using samples that fall outside the old image.

Diagnostics additions to consider during this work:

- Capture area divided by scope area.
- Current image bytes and peak tracked capture bytes, including retired images.
- Maximum requested sampling footprint.
- Capture count by generation and a reason code for recapture (content change,
  bounds expansion, DPR/quality change, or recovery).

Acceptance criteria:

- Unit tests prove required sample bounds are contained by capture bounds for
  the complete allowed configuration range.
- Pixel fixtures show no edge streaks, clamp bands, transparent seams, or
  unintended scale changes near crop boundaries.
- Overlay-only interaction continues to leave captureCount unchanged.
- Capture failures remain observable and route to fallback without an uncaught
  exception.

### WP3 — Add deterministic visual regression and renderer smoke tests

**Purpose:** test what the user sees, not only widget construction and shader
source structure.

Create integration_test coverage and reusable fixtures. Keep pure geometry and
configuration tests in test/.

Fixture backdrops:

1. Single vertical and horizontal high-contrast stripes for displacement
   direction and axis symmetry.
2. Checkerboard and fine grid for sampling aliasing and blur behavior.
3. Split light/dark and saturated-color fields for tint and adaptive response.
4. Text and vector lines under the glass plus foreground text above it.
5. A moving gradient for capture invalidation and stale-frame detection.

Visual assertions:

- A stripe beneath the edge moves in the expected direction; the center remains
  more stable than the bevel.
- X/Y distortion is symmetric for a symmetric config and fixture.
- Rounded rectangle, capsule, and circle/oval clipping match their shader
  silhouette.
- Foreground text remains unblurred and sharp in capture, filter, and fallback
  paths.
- A surface at a non-zero scope origin samples the matching crop coordinates.
- Multiple separated surfaces do not sample stale or unrelated pixels.
- Resize, DPR change, qualityScale change, rotation, and scrolling produce a
  correctly updated capture generation.
- Failed or unavailable capture displays the documented fallback and reports
  fallback through onRenderPathChanged.

Uniform contract tests:

1. Parse each shader’s ordered uniforms, excluding engine-owned values and
   samplers where the engine owns those slots.
2. Compare the parsed layout with an explicit Dart-side slot manifest or named
   binding table for both filter and capture paths.
3. Fail if a uniform is missing, renamed, reordered, bound twice, or declared
   but never set.
4. Compile/load both shader assets in a runtime-capable integration target.
5. Keep the existing total-count assertions as a quick check, not as the sole
   contract.

Golden strategy:

- Save references separately by backend family and DPR.
- Prefer semantic pixel assertions and bounded per-channel tolerance over exact
  cross-GPU image equality.
- Record Flutter revision, renderer, device, DPR, and fixture version beside
  each accepted baseline.
- Require a reviewer to inspect image diffs for intended shader changes.

Acceptance criteria:

- Every visual assertion has at least one capture-path run and one fallback
  run; filter-path assertions run only on an Impeller target.
- The test suite detects a deliberate sign flip in refraction, a shifted crop
  origin, an incorrectly ordered uniform, and a blurred foreground child.
- Integration failures preserve screenshots and runtime logs as artifacts.

### WP4 — Qualify the platform matrix with runtime evidence

**Purpose:** turn compatibility expectations into traceable results.

For each platform in scope, execute this scenario set:

1. Static backdrop with one small surface.
2. Animated or scrolling content behind one surface.
3. Four surfaces in one compact group.
4. Two surfaces far apart in the scope.
5. Surface movement across and beyond the original capture crop.
6. Resize and DPR change.
7. Surface attach/detach and scope disposal.
8. Foreground child containing text, an icon, and a composited widget.
9. Reduced motion, high contrast, and the reduced-transparency policy.
10. Forced fallback and forced filter path where the backend permits them.

Record for every run:

- Flutter and Dart version/revision.
- Platform, OS version, device/emulator model, and GPU where available.
- Renderer/backend: Impeller Metal, Impeller GLES, Impeller Vulkan, Skia,
  CanvasKit, or skwasm.
- Build mode, resolution, logical size, DPR, refresh rate, and power mode.
- Active render path and whether any fallback occurred.
- Capture bounds, pixel size, active surface count, capture count, estimated
  storage, and relevant failure logs.
- Screenshots of the fixture matrix and a short recording for interactive or
  scrolling cases.

Keep filter-path testing separate from capture-path testing. Specifically test
overlapping shader filters on a physical iOS device before advertising that
path as reliable; simulator success is not a substitute for device evidence.

Acceptance criteria:

- Every target in the declared support matrix has a completed row in
  doc/COMPATIBILITY.md, with the exact tested OS/renderer and date.
- Any untested backend says Unverified or Unsupported and documents the
  fallback behavior.
- No capture failure repeats every frame; failure count and fallback are
  visible in diagnostics.
- A 10-minute animated-content and repeated mount/dispose soak completes
  without stale images, crashes, unbounded image retention, or visible feedback.

### WP5 — Make the benchmark repeatable and low-interference

**Purpose:** measure renderer cost rather than the benchmark HUD.

Tasks:

1. Separate sampling from display refresh. Accumulate FrameTiming samples in a
   fixed-size buffer and update the HUD at a slower interval, such as four times
   per second, or freeze the HUD while a run is active.
2. Add a warm-up period and explicit Start/Stop controls. Clear samples between
   runs and discard warm-up samples.
3. Add static-background and animated-background variants.
4. Measure ordinary container, blur fallback, capture performance quality,
   capture balanced quality, capture ultra quality, forced filter where
   supported, and 1/4/10 surfaces. Include one overlap and one widely spaced
   surface scenario.
5. Report build and raster p50/p90/p99, worst observed frame, frame misses at
   8.33 ms and 16.67 ms, run duration, and sample count.
6. Calculate frame budget from the recorded refresh rate. Keep the 8.33/16.67
   ms reference columns for 120/60 Hz comparisons, but do not treat them as the
   only display budgets.
7. Export raw per-frame or histogram data and a JSON manifest to a local
   results directory. Do not include result files in the published package.
8. Track capture count, bounds, scale, memory estimate, and active path alongside
   frame timings.
9. Use DevTools or platform GPU tooling for GPU-specific timing. FrameTiming
   build/raster values alone are not GPU counters.
10. Run at least three repetitions per device/configuration after thermal
    stabilization. Report each run and a summary; do not publish only the best
    run.

Acceptance criteria:

- The same device/configuration produces results within a documented tolerance
  across repeated runs.
- The benchmark HUD does not trigger a full rebuild every frame during the
  sampling interval.
- Raw data can reproduce the displayed percentiles and budget misses.
- Results state whether they came from debug, profile, or release mode.

### WP6 — Add only evidence-driven optimization

**Purpose:** preserve visual quality while addressing measured hotspots.

Do not optimize by guesswork. First compare the benchmark matrix and DevTools
traces, then choose one targeted change at a time.

Candidate changes, only if profiling justifies them:

- Avoid evaluating dispersion samples when the selected preset/config disables
  dispersion.
- Avoid environment/reflection sampling when its contribution is zero or below
  a measured visibility threshold.
- Reduce large-surface texture sample count or introduce a shared blur level for
  repeated surfaces if the resulting image passes the visual fixture suite.
- Use smaller capture crops or separate scopes when distant surfaces make the
  bounding rectangle approach the whole scene.
- Retain capture qualityScale as an explicit quality tradeoff; do not silently
  lower it based on device heuristics until there is a validated policy.
- Preload shader programs before showing animated glass where shader startup is
  visible.

For every optimization:

1. Save the pre-change visual output and raw benchmark.
2. Change one cost driver.
3. Re-run all relevant visual fixtures and the same device benchmark.
4. Record visual differences and p50/p90/p99/worst-frame changes.
5. Keep the change only if it improves a measured target without violating the
   visual and compatibility gates.

Acceptance criteria:

- Each performance improvement has a before/after result from the same device,
  renderer, build mode, scene, and run protocol.
- No undocumented fallback or quality reduction is introduced.

### WP7 — Validate accessibility and interaction behavior

**Purpose:** make renderer fallback and material adaptation usable when visual
effects need to be reduced.

Tasks:

1. Preserve existing reduced-motion behavior and add tests that idle surfaces
   do not animate continuously.
2. Add a package policy input for reduced transparency because Flutter does not
   expose every platform’s transparency preference through the same
   cross-platform MediaQuery field. The application must be able to select an
   opaque or higher-opacity treatment explicitly.
3. Respect MediaQuery highContrast where available, with a documented override
   for apps that manage contrast themselves.
4. Add focus-state feedback for interactive glass surfaces so keyboard and
   accessibility focus are not visually invisible compared with pointer hover.
5. Verify labels and child semantics remain intact; decorative glass must not
   create duplicate semantic nodes.
6. Test text scaling and contrast on light, dark, photographic, and mixed
   backdrops. If the package cannot guarantee arbitrary child-text contrast,
   document that responsibility for app-owned foreground content.
7. Ensure every accessibility policy can choose the fallback or a higher
   opacity preset without requiring an Impeller shader.

Acceptance criteria:

- Widget tests cover reduced motion, high contrast, reduced transparency,
  focus, labels, and preservation of child actions.
- Manual screenshots cover the accessibility states in the platform matrix.
- No accessibility setting is claimed to be detected automatically unless the
  package actually reads it on that platform.

### WP8 — Update docs, package metadata, and release status

**Purpose:** make published expectations match measured behavior.

Tasks:

1. Replace placeholder homepage, repository, and issue-tracker URLs after the
   canonical source repository and package identity are confirmed.
2. Replace the starter text in example/README.md with setup, run, and renderer
   diagnostics instructions.
3. Update README installation instructions and state which platforms currently
   use capture, filter, or fallback.
4. Update doc/COMPATIBILITY.md from the completed matrix. Use Verified,
   Verified with fallback, Unverified, and Unsupported consistently.
5. Update doc/PERFORMANCE.md with the exact benchmark protocol and link to
   checked-in representative result manifests if suitable.
6. Update doc/RESEARCH.md with current Flutter API behavior and issue status.
   Flutter issue 188365 has been closed with an upstream change; recheck what
   that change means for the target SDK rather than retaining an old limitation
   statement unchanged.
7. Mark superseded sections in the 2026-10-20 capture design spec or replace
   them with a short link to the shipped implementation. The current spec still
   describes a shared blurred image that the implementation note says was not
   shipped.
8. Regenerate graphify output after source changes so the graph includes the
   scene, scope, group, and current shader bindings.
9. Update doc/RELEASE_CHECKLIST.md only with evidence-backed completed items.

Acceptance criteria:

- No placeholder repository URLs or generic starter docs remain.
- README, compatibility, performance, research, and release docs agree on the
  supported paths and tested platforms.
- The package dry-run archive contains only intended public files.
- All unverified states and known limitations are visible before publication.

## 6. Execution order and dependencies

Execute in this order:

1. WP0 freezes the target matrix and records the baseline.
2. WP1 establishes clean SDK and package checks.
3. WP2 defines the sample-footprint contract and fixes any confirmed bounds
   issue.
4. WP3 adds visual assertions before shader or capture optimization.
5. WP4 runs backend qualification against those assertions.
6. WP5 measures cost with the validated scenes.
7. WP6 applies one measured optimization at a time.
8. WP7 completes the accessibility behavior and verifies it on the chosen
   matrix.
9. WP8 updates support claims and release status from the evidence.

Do not start WP6 before WP3 and WP5 provide trustworthy visual and performance
baselines. Do not mark WP4 complete because a target compiled. Do not mark WP8
release items complete from code inspection alone.

## 7. Final milestone exit gate

The milestone is complete only when all applicable items are true:

- [ ] Minimum-SDK and latest-stable CI lanes pass.
- [ ] Formatting, analysis, package tests, example checks, and package dry-run
      pass from a clean checkout.
- [x] Uniform names, types, order, and Dart bindings are contract-tested for
      both shader paths.
- [x] Capture sample-footprint tests cover all supported qualities and legal
      configuration extremes.
- [x] Visual tests catch wrong refraction direction, crop mapping, clipping,
      blurred foreground, and incorrect fallback behavior.
- [x] Overlay-only interaction does not recapture static content.
- [x] Every advertised capture backend has runtime evidence; every other
      backend has an explicit status and fallback description.
- [ ] Physical iOS overlapping filter behavior is recorded separately from
      capture behavior before the filter path is advertised for that scenario.
- [ ] Benchmark runs include raw data, metadata, repeated runs, and refresh-rate
      context.
- [x] At least one representative 10-minute animated-content/disposal soak is
      recorded without lifecycle or visible feedback failures.
- [x] Reduced motion, high contrast, reduced transparency, focus, semantics,
      and text scaling have defined behavior and tests.
- [x] Placeholder package metadata and starter docs are removed.
- [ ] Compatibility and release documents match the evidence gathered.

If a device or browser is unavailable, keep its exit item unchecked and retain
that target as Unverified. The project may still release a narrower support
matrix, but must not claim the missing platform is verified.

## 8. Risks and mitigations

| Risk | Mitigation |
|---|---|
| CI passes while device rasterization fails | Keep device integration runs and runtime screenshots separate from compile jobs. |
| Pixel differences vary by GPU | Use backend-specific baselines and semantic sample assertions with justified tolerances. |
| Crop padding grows excessively | Report crop area and worst sample footprint; test compact and widely separated surfaces. |
| Capture images increase peak memory during retirement | Track current and peak estimated bytes; include repeated replacement and disposal in the soak. |
| Filter path behaves differently on physical iOS | Keep it separate from capture, test overlap on hardware, and document fallback/workaround. |
| Web capture works in one renderer but not the other | Qualify CanvasKit and skwasm independently and label each result. |
| New abstraction delays the milestone | Prefer a tested binding manifest before attempting a broad shader rewrite. |
| Accessibility setting is unavailable through Flutter on a platform | Expose a policy override; do not claim automatic detection. |
| Hardware access is delayed | Continue CI, contract, and desktop work; leave dependent platform statuses unverified. |

## 9. Rough effort and expected artifacts

Planning estimate: approximately 12–20 engineering days, excluding waiting time
for hardware access, CI provisioning, and review. The largest variable is
physical iOS and browser runtime qualification.

Expected artifacts:

- CI workflow and clean-checkout logs.
- Capture-footprint helper and unit tests.
- Shader uniform-layout contract tests.
- Deterministic integration fixtures and backend-specific screenshots.
- Updated benchmark harness and raw JSON result manifests.
- Platform compatibility matrix with device and renderer details.
- Updated README, example instructions, research notes, and release checklist.
- Refreshed graphify output matching the implementation after any source edits.

## 10. Research references to recheck during implementation

- Flutter fragment shaders: https://docs.flutter.dev/ui/design/graphics/fragment-shaders
- Flutter OffsetLayer.toImageSync: https://api.flutter.dev/flutter/rendering/OffsetLayer/toImageSync.html
- Flutter ImageFilter.shader capability: https://api.flutter.dev/flutter/dart-ui/ImageFilter/isShaderFilterSupported.html
- Flutter issue 187820, physical-device overlapping shader-backdrop report:
  https://github.com/flutter/flutter/issues/187820
- Flutter issue 188365, implicit sampler filter-quality change:
  https://github.com/flutter/flutter/issues/188365
- Apple Materials HIG: https://developer.apple.com/design/human-interface-guidelines/materials
- Apple Adopting Liquid Glass:
  https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass
- Flutter GPU status, if reconsidered for a separate experiment:
  https://github.com/flutter/flutter/blob/master/docs/engine/impeller/Flutter-GPU.md
