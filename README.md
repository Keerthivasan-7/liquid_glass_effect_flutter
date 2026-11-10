# liquid_optics_flutter

An independent, geometry-aware liquid-glass material for Flutter. Scoped capture samples a declared content plane, bends texture coordinates near the surface edge, and adds Fresnel and specular response. An Impeller-only filter can instead sample the compositor backdrop. This project is not affiliated with Apple.

> Status: `0.1.0-dev.1`, under active verification. See the [current execution record](doc/MILESTONE_PROGRESS.md) and [backend-specific evidence](doc/COMPATIBILITY.md). Physical-device qualification and repeatable performance results remain release gates.

## Why it is different

Conventional glassmorphism blurs a rectangular backdrop and adds a translucent fill. This package also computes a rounded-shape distance field, derives a local surface normal, displaces backdrop UV coordinates, bounds every sample, and optionally separates color channels near curved edges. Foreground children are painted after the optical pass and remain sharp.

## Installation

The public name is a release candidate and has not been reserved on pub.dev.
Use a local path dependency during development; a hosted source repository has
not been created yet. Adjust this path to the actual package folder:

```yaml
dependencies:
  liquid_optics_flutter:
    path: ../liquid_optics_flutter
```

## Quick start

Use `LiquidGlassScene` for app shells with scoped refraction. Check the
compatibility matrix before choosing a deployment target. The content plane is captured first; glass remains
in the functional overlay and can never recursively capture itself:

```dart
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

LiquidGlassScene(
  content: const YourScrollableContent(),
  glass: LiquidGlassGroup(
    influenceRadius: 180,
    child: Center(
      child: LiquidGlass(
        config: const LiquidGlassConfig.clear(),
        interactive: true,
        padding: const EdgeInsets.all(24),
        child: const Text('Liquid Glass'),
      ),
    ),
  ),
)
```

The simplest use is `LiquidGlass(child: ...)`. The balanced preset is the default.

## Material controls

- `blurSigma` controls shader blur independently from refraction.
- `refractiveIndex`, `refractionStrength`, `thickness`, `curvature`, `edgeWidth`, and `maxDisplacement` govern Snell-style bounded UV displacement.
- `cornerSmoothing` controls the p-norm corner profile; `innerShadow` controls bezel depth.
- `fresnelStrength` and `specularStrength` control edge reflectance and directional highlights.
- `roughness`, `transmission`, `absorptionColor`, `absorptionStrength`, and
  `scatteringStrength` define the transmissive body and volume attenuation.
- `dispersionStrength` and `abbeNumber` provide IOR-derived RGB dispersion;
  `chromaticAberration` remains a small artistic screen-space offset.
- `coatStrength`, `coatRoughness`, and `coatRefractiveIndex` add a second
  dielectric reflection lobe.
- `thinFilmThickness`, `thinFilmRefractiveIndex`, and `thinFilmStrength` add
  view-dependent interference to the coat.
- `anisotropy`, `anisotropyRotation`, `environmentStrength`, `lightColor`,
  `lightIntensity`, and `causticStrength` control directional lighting.
- `quality` selects one, nine, or seventeen normalized transmission samples.
- `renderer` can force `capture`, the Impeller `shader` filter, or `fallback`.
- `onRenderPathChanged` reports `capture`, `filter`, or `fallback` for diagnostics.
- `animateLight` is off by default and respects reduced-motion/accessibility signals.
- `interactive` adds pointer-local deformation and restrained hover/press feedback without consuming child gestures.
- `motionStrength` controls velocity-driven normal deformation and the moving
  edge glint. Wrap related interactive surfaces in `LiquidGlassGroup` to share
  one damped pointer/touch field; `influenceRadius`, `motionGain`, and
  `settleDuration` tune its reach and response.

Available shapes are rounded rectangles, capsules, and circles. The canonical
materials are `LiquidGlassConfig.regular()` and `.clear()`. The older
`.crystal()` constructor remains as an alias for `.clear()`; `.frosted()` and
`.performance()` provide stronger scatter and lower-cost alternatives.

## Rendering architecture

The portable path uses `LiquidGlassScene`/`LiquidGlassScope` to paint its content
into a separate background layer. Changed background content is captured just
before scene composition, including scrolling children that repaint without
repainting the scope. Surfaces share that image and bind the current generation
in the same composition pass. Each canvas fragment shader maps local geometry
into the capture using a 2D affine transform. Replaced image generations remain
alive for two completed frames before disposal.

The functional overlay is isolated by a repaint boundary, so hover, press, and
other overlay-only animation reuse the current capture. The captured rectangle
is bounded to the union of active glass sampling regions plus their blur and
displacement padding. `onDiagnosticsChanged` reports capture generations,
failures, active surfaces, logical/pixel bounds, pixel ratio, and estimated RGBA
storage. Crop bounds round outward on the effective texel grid, preserving
sampling alignment when a fractional-DPR crop expands. See the
[capture contract](doc/CAPTURE_CONTRACT.md).

When no scope is present, the filter path uses
`BackdropFilter(ImageFilter.shader(...))`; Flutter supplies the prior backdrop
as its sampler. This remains available explicitly for backend qualification. If capture or
shader filtering is unavailable, the package uses
`BackdropFilter(ImageFilter.blur(...))` plus clipping, tint, and edge decoration.

Test overlapping shader filters on target devices. Capture surfaces share one scope image; filter surfaces use individual compositor regions. Flutter issue 187820 reported physical-iOS feedback and was closed without a demonstrated fix. See [COMPATIBILITY.md](doc/COMPATIBILITY.md).

## Accessibility

Foreground content is painted after the optics. Continuous animation is opt-in.
`MediaQuery.disableAnimations`, `accessibleNavigation`, and `reduceMotion` stop
material motion. Keyboard focus within an interactive surface and accessibility
focus on a labeled surface receive a two-tone focus ring without taking child actions.

```dart
LiquidGlass(
  accessibility: const LiquidGlassAccessibilityPolicy(
    reduceTransparency: true,
    reduceMotion: true,
    // highContrast: null follows MediaQuery; false explicitly overrides it.
  ),
  child: const Text('Readable controls'),
)
```

Reduced transparency or high contrast uses an opaque theme surface, without
capture, shader, or backdrop blur. `opaqueColor` can override that surface.
Inherited text/icon colors adapt to its luminance; explicitly styled children
remain the application's responsibility. Reduced transparency is an explicit
app preference because Flutter does not expose a universal platform signal.

## Performance

Use the smallest practical glass bounds, prefer `performance` or `balanced` for repeated surfaces, avoid animating layout, and profile on target hardware. The benchmark records build/raster p50, p90, p99, and budget misses from actual `FrameTiming` samples; this repository intentionally contains no invented FPS claims.

```powershell
cd benchmark
flutter run --profile
```

## Run and verify

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/integration_test example/test_driver benchmark/lib benchmark/test
flutter analyze
flutter test
flutter pub publish --dry-run

cd example
flutter run
```

The example has Materials, Controls and Comfort screens, four selectable
presets, fine adjustments and accessibility previews. It uses `LiquidGlassScene`:
solid content is captured first and functional controls are composited on top.
Capture support is runtime-gated and downgrades safely to blur/tint.
See the [showcase instructions](example/README.md) and
[complete integration example](doc/INTEGRATION_GUIDE.md).

## Project documentation

- [App integration guide](doc/INTEGRATION_GUIDE.md)
- [Delivery plan for 13 November](doc/FOUR_DAY_DELIVERY.md)
- [Development handoff notes](doc/DELIVERY_NOTES.md)
- [Implementation plan](doc/IMPLEMENTATION_PLAN.md)
- [Verified Portable Renderer milestone](doc/VERIFIED_PORTABLE_RENDERER_PLAN.md)
- [Flutter and web reference comparison](doc/REFERENCE_COMPARISON.md)
- [Capture sampling and resource contract](doc/CAPTURE_CONTRACT.md)
- [Research and decisions](doc/RESEARCH.md)
- [Engineering report](doc/ENGINEERING_REPORT.md)
- [Compatibility matrix](doc/COMPATIBILITY.md)
- [Performance protocol](doc/PERFORMANCE.md)
- [Physical optics model](doc/PHYSICS_MODEL.md)
- [Release checklist](doc/RELEASE_CHECKLIST.md)

## Troubleshooting

- **Only blur/tint is visible:** observe `onRenderPathChanged`, use a capture scope for the portable path, and inspect capture failures. Shader filtering requires Impeller. Accessibility policies can intentionally select opaque fallback.
- **Nothing bends:** ensure the glass is later in paint order than a high-contrast background and refraction is non-zero.
- **Edges look clipped:** reduce `maxDisplacement` or avoid placing the surface flush against its parent's clip.
- **Scrolling is slow:** reduce surface area and count, use `performance`, and disable moving highlights.

## License and attribution

BSD-3-Clause. Research references and source identities are recorded in
[REFERENCE_COMPARISON.md](doc/REFERENCE_COMPARISON.md). Reference libraries are
not runtime dependencies; their implementation source was not copied into this package.
