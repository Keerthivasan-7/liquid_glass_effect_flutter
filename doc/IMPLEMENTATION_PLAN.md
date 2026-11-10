# Liquid Optics Flutter — production implementation plan

Status: active · Baseline: `0.1.0-dev.1` · Updated: 2026-11-04

## Next milestone

The next implementation target is **Verified Portable Renderer**: prove the
current capture, filter, and fallback paths with deterministic visual checks,
reproducible performance data, and a truthful platform support matrix. The
detailed work packages, test design, sequencing, and exit gates are in
[VERIFIED_PORTABLE_RENDERER_PLAN.md](VERIFIED_PORTABLE_RENDERER_PLAN.md).

## 1. Product goal

Build the strongest practical, independent Liquid Glass-style material available
to Flutter while remaining honest about the boundary: Apple does not publish its
private compositor or shader source. Fidelity is judged against Apple's public
behavior, APIs, design guidance, accessibility behavior, and visual output—not
against unverifiable source parity.

The package must deliver:

1. real backdrop refraction rather than blur-only glassmorphism;
2. a top-level content/functional-layer architecture that cannot recursively sample glass;
3. dynamic, local interaction response;
4. adaptive Regular and Clear material families;
5. grouped glass that can share work and eventually morph;
6. deterministic degradation on unsupported renderers;
7. evidence from pixel tests and percentile performance measurements;
8. a sparse, production-quality example that demonstrates correct usage.

## 2. Non-negotiable quality gates

No milestone is complete until all applicable gates pass.

| Gate | Requirement |
|---|---|
| Correctness | Sample the intended content layer; keep foreground children sharp; prevent feedback and stale-frame sampling. |
| Visual | Pixel tests cover refraction direction, blur symmetry, rim response, mixed luminance, interaction, and resizing. |
| Performance | Report p50/p90/p99 build and raster times, missed-frame rate, surface count, resolution, renderer, and capture scale. |
| Accessibility | Test reduced motion, high contrast, text scaling, focus, semantics, and transparency reduction. |
| Compatibility | Windows, Android, iOS, macOS, and web are verified or explicitly marked unverified/unsupported. |
| API | Changes are additive until 1.0; deprecated behavior has migration guidance. |
| Release | Format, analyze, tests, example builds, benchmark build, and package dry-run pass without package-hygiene warnings. |

## 3. Architecture target

### 3.1 Scene composition

The canonical API is a two-plane scene:

```dart
LiquidGlassScene(
  content: AppContent(),
  glass: FloatingNavigationAndControls(),
)
```

`content` is the complete visual plane that glass may sample. `glass` is the
functional overlay and is excluded from capture. `LiquidGlassScope` remains the
lower-level compatibility API.

- Glass belongs in the overlay plane, not in ordinary content cards.
- Nested glass is forbidden by default. Grouped glass uses one explicit group.
- Capture invalidation follows content changes, not unrelated overlay animation.
- Capture bounds should reduce to active sampling regions where engine constraints permit.
- A failed capture is observable and falls back; it never silently claims refraction.

### 3.2 Rendering backends

| Backend | Preferred path | Fallback |
|---|---|---|
| Impeller with shader backdrop filters | compositor backdrop shader | blur/tint |
| Skia desktop | captured content texture | blur/tint |
| Web renderer supporting layer capture | captured content texture | blur/tint |
| Unsupported/failed capture | explicit fallback | static translucent fill if blur is unavailable |

All paths share material semantics. Optical strength may be reduced on a
fallback, but naming and accessibility behavior remain stable.

### 3.3 Material model

Phase 1 keeps the current SDF and adds symmetric multi-direction sampling,
pointer-local deformation and illumination, stable bounded displacement, and a
documented/tested uniform layout.

Phase 2 adds `regular` and `clear` materials, luminance-aware tint and foreground
polarity, backdrop dimming, view/tilt input, environment lighting, and a
transmitted-light approximation.

Phase 3 adds a shared blur pyramid or atlas so blur cost is paid per scene rather
than per surface, plus `LiquidGlassGroup` for shared rendering and morphing.

## 4. Work breakdown

### Milestone 0 — trustworthy foundation

- [x] Independent Apple-guideline and code audit.
- [x] Static analysis, tests, Windows example build, web build, and package dry-run baseline.
- [x] Curated skill/plugin review; no external account dependency required.
- [x] Update the installed graphify skill to match the installed package.
- [x] Add `LiquidGlassScene` as the canonical content/overlay contract.
- [x] Make the benchmark execute the capture renderer and display p50/p90/p99.
- [x] Add a Windows benchmark runner.
- [x] Exclude internal graph/build artifacts from the published archive.
- [x] Replace directional cross sampling with a normalized isotropic kernel.
- [x] Add opt-in pointer-local interaction with reduced-motion-safe scaling.
- [x] Add tests for scene composition, interaction lifecycle, and shader layout.

Exit: all local gates pass and the benchmark reports `capture` for capture cases.

### Milestone 1 — capture architecture v3

- [x] Separate content invalidation from overlay invalidation.
- [x] Cache capture until content, size, DPR, capture quality, or required bounds change.
- [x] Track active sample rectangles and capture their padded union.
- [x] Add generation IDs and diagnostics: captures, bytes, failures, surfaces, bounds, and timestamp.
- [x] Test content/overlay invalidation, movement, quality changes, and rapid disposal.
- [ ] Add dedicated scrolling, theme, and variable-window-size integration tests.
- [ ] Qualify `toImageSync` across the full matrix. Windows profile runtime is
  verified; CanvasKit and skwasm runtime validation remains.

Exit: overlay-only animation does not force a full content capture; no leaked or
prematurely disposed images over a 10-minute stress run.

### Milestone 2 — adaptive material system

- [x] Add calibrated `LiquidGlassConfig.regular()` and `.clear()` materials.
- [x] Downsample the scope capture with a configurable quality scale.
- [x] Adapt tint and directional edge light to sampled backdrop luminance.
- [x] Demonstrate explicit foreground polarity in adaptive light/dark scenes.
- [ ] Add a reusable package-level foreground-theme policy.
- Add Clear backdrop dimming policy with an explicit opt-out.
- Implement reduce-transparency and high-contrast modes.
- Verify contrast for package-owned icons and labels in the example.

Exit: golden matrix across dark, light, mixed, photo, high-contrast, and reduced-
transparency environments.

### Milestone 3 — interaction and motion

- [x] Touch/hover-local internal illumination.
- [x] Press depth and interruptible elastic release.
- [x] Drag velocity/direction influence the optical normal within safe bounds.
- [x] Reduced Motion disables elasticity while retaining state feedback.
- Focus and keyboard interaction receive equal visual and semantic treatment.

Exit: interaction tests cover mouse, touch, keyboard, interruption, and reduced
motion; no continuous animation when idle.

### Milestone 4 — grouped glass and morphing

- [x] Introduce `LiquidGlassGroup` with a shared damped motion field.
- [x] Reuse the scope's shared capture while group-only animation repaints the
  optical foreground without requesting a new background capture.
- [x] Implement a proximity field for velocity, touch energy, and glints.
- Implement a true union contour across independently laid-out surfaces.
- Morph insertion, removal, selection, and control expansion.
- Prevent accidental glass-on-glass and expose debug diagnostics.

Exit: deterministic morph goldens and performance within the agreed budget for
four grouped controls.

### Milestone 5 — optics and lighting refinement

- [x] Calibrated IOR with bounded Snell refraction and Abbe dispersion.
- [x] Better thickness profile and continuous analytic normal.
- [x] Environment-proxy reflection plus anisotropic GGX base and coat lobes.
- [x] Beer–Lambert absorption, volume scatter, and directional caustic.
- [x] Energy-normalized rough-transmission kernels.
- [x] Optional RGB thin-film interference approximation.
- [ ] Perspective/view vector and optional device tilt.
- [ ] Shared Gaussian pyramid for large-radius scatter.
- Wide-gamut/HDR and premultiplied-alpha verification.

Exit: reference scenes at 1×, 2×, and 3× DPR have no directional blur, clipping,
halos, NaNs, or obvious banding.

### Milestone 6 — example and design system

- Replace the giant glass content card with scrolling content plus sparse
  floating navigation and contextual controls.
- Use concentric geometry, platform-appropriate typography, and optical spacing.
- Add diagnostics showing renderer, capture scale, surface count, and percentiles.
- Provide Regular/Clear, interaction, accessibility, and stress-test scenes.

Exit: the default screenshot demonstrates correct product usage, not only shader
capability.

### Milestone 7 — qualification and release

- Run the device/browser matrix in profile/release mode.
- Store reproducible benchmark JSON and reference screenshots.
- Complete API docs, migration guide, troubleshooting, and limitations.
- Remove stale claims and internal artifacts from the package.
- Validate license, package name, repository links, and pub score.

Exit: zero analyzer/test/package warnings and no unqualified parity or FPS claim.

## 5. Measurement protocol

Each benchmark result records Flutter/Dart versions; OS/device/GPU; resolution,
DPR, refresh rate, and renderer; scene and surface geometry; capture quality;
warm-up and sample counts; build/raster p50, p90, p99 and worst frame; frames
over 8.33 ms and 16.67 ms; available process/GPU memory; and capture diagnostics.

Means alone are not accepted because they hide visible stalls.

## 6. Test strategy

1. Unit: configuration, shapes, percentile math, and invalidation policy.
2. Shader contracts: uniform order/count, finite guards, and sampling symmetry.
3. Widget: renderer selection, scene ownership, input lifecycle, semantics,
   accessibility, resizing, and disposal.
4. Pixel: synthetic stripe/checker scenes with known displacement and blur symmetry.
5. Integration: runtime-shader capture on Windows and at least one Impeller device.
6. Stress: 1/4/10 surfaces, static/dynamic content, overlap, scrolling, resize,
   and a 10-minute lifecycle soak.

## 7. Risk register

| Risk | Response |
|---|---|
| Full-scope synchronous capture stalls | Cache by content generation, bound capture, lower scale, and publish measured limits. |
| Browser layer capture fails | Detect once, expose the active path, and use deterministic fallback. |
| Shader behavior differs by backend | Contract and platform pixel tests; tune only behind capability flags. |
| Adaptive tint harms color/contrast | Constrain adaptation, allow policy override, and test luminance fixtures. |
| Group morphing multiplies cost | Share resources and impose documented group/surface limits. |
| Demo encourages misuse | Make the canonical example a content plane with sparse functional overlays. |

## 8. Definition of “best”

The project can claim best-in-class only with independently reproducible evidence
combining visual fidelity, dynamic behavior, accessibility, Flutter coverage,
stable APIs, and competitive percentile frame times. A polished screenshot or
shader alone is not sufficient.
