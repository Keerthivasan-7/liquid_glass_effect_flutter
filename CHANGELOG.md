# Changelog

## 0.1.0-dev.1

- Added functional Materials, Controls and Comfort showcase screens, four
  presets, session favorites, resettable fine adjustments, responsive navigation
  and app-wide comfort previews. Isolated diagnostics updates from page builds.
- Added a complete app integration guide and explicit development handoff scope.
- Precompute material rotation axes on the CPU for reuse in capture/filter sampling and highlights; preserve optical settings and sample counts.

- Anchor capture crops to the effective texel grid so fractional capture ratios
  preserve checkerboard/scatter output when the shared crop expands.

- Hardened portable capture bounds for scattering, reflection, anisotropy,
  fractional capture ratios, affine transforms, and interactive scale overshoot.
- Fixed stale captured images behind retained foreground boundaries, convex
  refraction direction, pixel-space anisotropy, and per-batch image retirement.
- Separated filter surface geometry from render-target coordinates and bound
  retained offsets during composition; qualified explicit filter displacement.
- Fixed skwasm retained-picture disposal with guarded retirement and stable
  picture reuse.
- Fixed capture freshness for independently repainted scrolling content by
  refreshing at background-layer composition while retaining static captures.
- Added stripe, split-field, text/vector and actual-scroll pixel contracts,
  plus rejection of delayed pre-start benchmark timings.
- Added explicit transparency/motion/contrast accessibility policies, opaque
  material fallback, and keyboard/accessibility focus feedback.
- Added semantic uniform-binding checks, rendered-pixel contracts, native
  integration fixtures, lifecycle soak tooling, and minimum/stable CI lanes.
- Rebuilt the benchmark around warm-up, timestamped raw samples, repeatable
  cases, native/browser JSON export, and incomplete-run qualification flags.
- Removed placeholder repository URLs pending the canonical source identity.

- Rebuilt the showcase around a canonical content plane and sparse floating
  control layer, with adaptive light/dark scenes and live optical tuning.
- Added `regular` and `clear` material presets; retained `crystal` as a
  source-compatible alias for `clear`.
- Replaced the uniform double rim with backdrop-aware tint, directional edge
  illumination, restrained shadow, and a narrow transmitted-light caustic.
- Rebuilt the optical core as a layered dielectric material inspired by
  Blender/OpenPBR controls: rough transmission, Beer–Lambert absorption,
  volume scatter, Abbe-number dispersion, anisotropic GGX reflection, a second
  dielectric coat, optional thin-film interference, environment reflection,
  colored lighting, and controllable caustics.
- Expanded `LiquidGlassConfig` with public parameters for every new physical
  layer and exposed the primary controls in the example optics panel.
- Expanded balanced/ultra blur to normalized 9/17-tap kernels and confined
  chromatic separation to the outer optical edge.
- Roughened environment reflection with the same anisotropic sampling model as
  transmission and replaced the last fixed-dark bezel term with adaptive
  light/dark contrast derived from the live backdrop.
- Added `LiquidGlassGroup`, a shared pointer/touch proximity field with damped
  inertial settling, sibling influence, reduced-motion handling, and no gesture
  arena interference.
- Added velocity-driven shader normal advection, a trailing refractive wake,
  directional motion glints, and the public `motionStrength` material control.
- Fixed an Android Impeller paint-lifecycle failure by clipping foreground
  children through the rendering context rather than retaining a stale canvas
  across composited child painting.
- Added Android emulator debug/profile runtime and screenshot validation on
  Impeller OpenGL ES.
- Reduced the default portable capture scale from 0.75 to 0.65 after profile
  comparison against the compositor filter on the Android emulator.
- Added `LiquidGlassScope` and a portable captured-texture renderer for Windows,
  web, and Skia backends with automatic failure fallback.
- Added `LiquidGlassScene` as the canonical two-plane content/glass composition API.
- Isolated the glass overlay from content capture invalidation and bounded each
  snapshot to the union of active padded sampling regions.
- Added immutable capture diagnostics for generations, failures, bounds, active
  surfaces, pixel dimensions, estimated bytes, and capture timestamp.
- Retire the cached texture after the final capture surface detaches instead of
  retaining unused GPU memory for the remaining scope lifetime.
- Added a second canvas fragment shader with p-norm corners, analytic normals,
  Snell-style refraction, normal-derived Fresnel, and directional edge light.
- Added `refractiveIndex`, `cornerSmoothing`, `innerShadow`, renderer-path
  diagnostics, and explicit `capture` renderer selection.
- Removed double tinting and retained captured image generations across raster
  frames before disposal.
- Added a real compositor-backdrop shader path with bounded geometry-aware refraction.
- Added shader blur, Fresnel response, specular lighting, tint, saturation, noise, and optional chromatic separation.
- Added rounded rectangle, capsule, and circle geometry shared by clipping and shader uniforms.
- Added clear/crystal, regular/balanced, frosted, and performance materials.
- Added capability-based fallback rendering and reduced-motion handling.
- Added opt-in pointer-local optical deformation and reduced-motion-safe hover/press feedback.
- Replaced cross-only shader blur sampling with a normalized eight-direction kernel.
- Added a two-plane adaptive showcase, a Windows profile benchmark with build/raster
  percentiles and budget misses, tests, and engineering documentation.
- Excluded benchmark, graph, and build artifacts from the published package.
- Changed shader program caching to store resolved programs rather than
  cross-zone futures and made failed loads retryable.
