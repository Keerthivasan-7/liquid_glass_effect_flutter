# Capture renderer and optics v2 — design

Date: 2026-10-20 · Package: `liquid_optics_flutter` (0.1.0-dev.1) · Status: historical design; superseded

This document records the original proposal and its then-current findings. It
is not the current renderer/support specification. Use
[the capture contract](../../../doc/CAPTURE_CONTRACT.md),
[the portable-renderer milestone](../../../doc/VERIFIED_PORTABLE_RENDERER_PLAN.md),
and [the current evidence](../../../doc/MILESTONE_PROGRESS.md). Shared preblur
was not shipped, and later work added interaction, accessibility, affine capture
mapping, and independent filter qualification. Historical goals and diagrams
below must not be read as current implementation or support claims.

Implementation note: the shipped capture path retains one sharp scope image and
performs blur in each surface shader. This intentionally replaces the proposed
single shared blurred image, which cannot represent different `blurSigma` values
for multiple surfaces without approximation.

## 1. Goal

Make real lens-style refraction work on every platform Flutter runs on, including Windows and web, and bring the optics closer to Apple's Liquid Glass.

Today the shader only runs through `ImageFilter.shader`, which is Impeller-only. On Windows, web and Skia fallbacks the package draws a plain blur and tint. That is conventional glassmorphism, and the developer's own machine cannot show the headline feature.

### Success criteria (all measurable)

1. On Windows, inside a `LiquidGlassScope`, `LiquidGlass.debugRenderPath` reports `capture`. A pixel test shows background content under the bezel is displaced relative to the same content outside the glass.
2. The old and new optics can be compared side by side in the example app on Windows.
3. Foreground children stay sharp: a test shows child pixels are unaffected by blur and refraction.
4. `flutter analyze` is clean and all tests pass. Results are recorded in `doc/ENGINEERING_REPORT.md`.
5. Benchmarks compare the capture path with the fallback on Windows. Only measured numbers are recorded. Android and iOS remain unverified unless a device is available, and the docs say so.

### Non-goals (second spec)

Press and touch response, grouped glass and metaball merging, morphing transitions, contrast adaptation over light or dark content, tilt-driven light. Also out of scope: any claim of parity with Apple's private renderer.

## 2. Findings that drive the design

- `shaders/liquid_glass.frag` pushes pixels along the SDF gradient with `pow(edge, k)`. There is no height profile and no refraction through a normal.
- Blur is a 5 or 9-tap cross with sigma-scaled offsets. It will ghost and band at sigma 7 and above.
- Fresnel's `cosTheta` is derived from the edge falloff, not from a surface normal.
- Highlights are a single `pow(dot, 18)` lobe. Corners are circular arcs.
- `LiquidGlass` applies the tint twice: once in the shader and again in `_GlassOverlayPainter`. The border is a generic linear gradient, and uniforms are rebound on every build.

## 3. Architecture

### 3.1 Three render paths, chosen explicitly

| Path | When | Mechanism |
|---|---|---|
| `filter` | No scope, `ImageFilter.isShaderFilterSupported` is true | Existing `BackdropFilter` plus `ImageFilter.shader` |
| `capture` | Inside a `LiquidGlassScope` | Canvas shader samples a captured background image |
| `fallback` | Neither, or `renderer: fallback` | `BackdropFilter` blur plus tint |

`LiquidGlass.debugRenderPath` (and an internal enum) reports the active path. Nothing downgrades silently. `LiquidGlassRenderer.auto` prefers `capture`, then `filter`, then `fallback`. The existing `shader` and `fallback` values keep their meaning.

### 3.2 `LiquidGlassScope`

```dart
LiquidGlassScope(
  background: MyBackground(),   // captured, painted first
  child: Stack(children: [ LiquidGlass(...), ... ]), // painted above, never captured
)
```

- A render object with two children, `background` and `child`. In `paint`, it paints the background through an `OffsetLayer`, snapshots that layer with `OffsetLayer.toImageSync(bounds, pixelRatio)`, then paints `child`. The glass widgets are in `child`, so they can never capture themselves.
- The scope is one repaint unit. When the background repaints, the scope repaints, and with it every glass surface inside. Glass surfaces are not separate repaint boundaries, because they would hold a stale image. This is a documented limit of v1.
- Capture resolution is `devicePixelRatio × qualityScale` (performance 0.5, balanced 0.75, ultra 1.0). `pixelRatio` is configurable on the scope.
- A second, blurred image is made only when a glass surface in the scope has `blurSigma > 0`. It is produced once per frame, shared by all surfaces, by drawing the sharp image through `ImageFilter.blur` at half resolution. Flutter's own Gaussian replaces the per-pixel tap cross.
- Images are disposed after the frame that used them (post-frame callback), never while the layer tree can still reference them. The scope also disposes everything on `dispose` and on resize.
- `LiquidGlass` finds its scope through an `InheritedWidget`. The scope exposes the current images and the scope's size. Each glass render object reads them at paint time, which is after the scope has captured, because the background paints before the child.

### 3.3 Shader layout

One optics core, two thin entry points. Both use the same uniforms apart from the extra sampler.

```
shaders/
  lib/optics.glsl                  # SDF, bezel profile, refraction, lighting
  liquid_glass_filter.frag         # one sampler (engine-owned filter input)
  liquid_glass_canvas.frag         # two samplers: u_sharp, u_blur
```

The unified mapping, for both paths:

```
bg_uv = (u_origin + frag_local) / u_scope_size
```

On the filter path `u_origin = 0` and `u_scope_size = u_size`. On the capture path `u_origin` is the glass's offset inside the scope, in image pixels.

All Y-flip handling for `IMPELLER_TARGET_OPENGLES` lives once, in the core. Uniform slots are documented by a table in `shader_manager.dart`, and the contract test asserts the Dart-side count against the GLSL.

## 4. Optics v2

Evaluated per pixel in `optics.glsl`.

1. **Shape and normal.** The rounded-rectangle SDF's corner term uses a p-norm, `p = mix(2, 5, cornerSmoothing)`, for continuous corners. It is no longer a circular arc, and it is not an exact Euclidean distance. The 2D normal comes from the analytic gradient, not finite differences. Capsule, circle and ellipse stay special-cased.
2. **Bezel depth.** `t = clamp(depth_inside / bezelWidth, 0, 1)`, where `depth_inside = -sdf`.
3. **Height profile.** `h(t) = (1 - (1 - t)^n)^(1/n)`, with `n` mapped from `curvature` into [2, 8]. Its derivative `dh/dt` gives the surface slope.
4. **Surface normal in 3D.** `N = normalize(vec3(-dh/dt · n2d, 1))`. At the flat center, `N = (0, 0, 1)`.
5. **Refraction.** Incident ray `I = (0, 0, -1)`. `R = refract(I, N, 1 / refractiveIndex)`. Displacement is `thickness · R.xy / abs(R.z)`, soft-clamped to `maxDisplacement` with a smooth saturating function. It is not a hard `min`, so there is no visible kink.
6. **Sampling.** The displaced UV is clamped to the image with a padded border. Blur is a mix of `u_sharp` and `u_blur`, weighted by the normalized `blurSigma`.
7. **Chromatic aberration.** Per-channel offsets along the refracted direction, weighted by the bezel, as now. Only at `ultra`.
8. **Fresnel.** `F = F0 + (1 - F0) · (1 - N·V)^5`, with `V = (0, 0, 1)` and the real `N`.
9. **Rim light.** A dual-lobe rim along the bezel. The lit-side lobe is strong, and the opposite lobe is about 35% as strong. Both are modulated by the normal and the light direction. A shader-drawn rim replaces the gradient border stroke.
10. **Inner shadow.** A soft darkening just inside the bezel, opposite the light, scaled by `innerShadow`.
11. **Tint and grain.** Applied once, in the shader, in premultiplied alpha. Grain is deterministic and not time-animated.

All divisions are guarded, and outputs are `clamp`ed. The shader never emits NaN or Inf, including at zero size.

### Public API changes (additive)

New `LiquidGlassConfig` fields: `refractiveIndex` (1.0 to 2.0, default 1.45), `cornerSmoothing` (0 to 1, default 0.6), `innerShadow` (0 to 1, default 0.25). New widget `LiquidGlassScope`. New enum `LiquidGlassRenderPath` and `LiquidGlass.debugRenderPath`. Existing fields keep their names. `curvature` now selects the profile exponent. `refractionStrength` scales `thickness`. Presets are retuned from visual testing and called out in the CHANGELOG. `_GlassOverlayPainter`'s tint is removed, and the border becomes a shader or fallback-only element, so the double tint is fixed.

## 5. Error handling

- Shader load failure: fall back to the `fallback` path and log in debug. `debugRenderPath` reports it.
- A scope with zero size, or a capture failure: use `fallback` for that frame. Do not throw.
- Glass outside any scope with no filter support: `fallback`, and an assert-time hint tells the developer to wrap their background in `LiquidGlassScope`.
- Reduced motion and `animateLight` behave as they do today.

## 6. Testing

- **Unit:** config validation for the new fields, `copyWith` and `==`, path selection logic, bezel and refraction math ported to Dart for table tests (the Dart mirror is test-only).
- **Shader contract:** uniform count and order, sampler order, presence of `FlutterFragCoord()` and the OpenGL ES flip, `#include` resolution, no NaN guards missing.
- **Widget:** scope captures and disposes images, glass outside a scope falls back, children remain unblurred, resize and repeated create and destroy.
- **Rendering:** `capture` path on Windows, via integration test with pixel assertions (displacement under the bezel, sharp child). Goldens on `capture` are attempted in `flutter test`. If `flutter_tester` cannot rasterize runtime shaders, they run under `integration_test` on Windows instead. The spike decides which.
- **Benchmark:** extend `benchmark/` to compare `fallback`, `filter` (where supported) and `capture`. Record device, Flutter version, renderer and measured frame times. Never invent numbers.

## 7. Risks and spike gates (Phase 1 must settle these)

1. **`#include` of a shared GLSL core** may not resolve under Flutter's shader compiler. Fallback: a `tool/` script that concatenates the core into both entry points, with the generated files checked in and a test asserting they are in sync.
2. **`toImageSync` inside `paint`** on Windows Skia and on web (CanvasKit or skwasm). Verify it works, doesn't leak, and doesn't stall the raster thread. Fallback: a lower `pixelRatio`.
3. **Passing a captured `ui.Image` to `FragmentShader.setImageSampler` and disposing it afterward.** Dispose after the frame is the plan. Verify there is no use-after-dispose.
4. **`ImageFilter.compose(outer: shader, inner: blur)`** on Impeller for the `filter` path. Cannot be tested on Windows. If it can't be verified, the filter path keeps a documented single-pass blur, and this is reported as unverified.
5. **Shader goldens under `flutter test`** may not be possible (see §6).
6. **Cost of a full-scope repaint** with large animated backgrounds. Measured in the benchmark, and documented.

If risks 2 or 3 fail on Windows, I stop and report. The capture design would then need rework rather than workarounds.

## 8. Phasing

1. **Spike (throwaway):** minimal scope plus canvas shader plus `#include`, running on Windows. Gate on risks 1 to 3. Report before building on it.
2. **Capture renderer:** `LiquidGlassScope`, the `capture` path, image lifecycle, path selection, `debugRenderPath`, and fixes for the double tint and uniform caching.
3. **Optics v2:** the shared core, new uniforms, retuned presets, blur chain.
4. **Verification:** tests, benchmark extension, example A/B toggle, docs (README, COMPATIBILITY, ENGINEERING_REPORT) updated with measured results only.

## 9. Open questions

None blocking. Mobile Impeller behavior, including the `compose` chain and the reported iOS overlapping-filter issue, stays unverified until a device is available.
