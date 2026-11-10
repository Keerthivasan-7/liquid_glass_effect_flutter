# Flutter and web liquid-glass comparison

Researched 2026-11-06. The two Flutter archives were downloaded at the exact
requested versions and their SHA-256 hashes checked against pub.dev. Selected
web sources were read at fixed Git commits. Source identities and repository
statistics are recorded in `doc/evidence/reference-source-manifest-2026-11-06.json`
and `doc/evidence/reference-repositories-2026-11-06.json`.

## Which references are most useful for this project

| Reference | GitHub stars observed | What its code contributes | How to use it here |
|---|---:|---|---|
| [liquid_glass_easy 5.2.0](https://github.com/AhmeedGamil/liquid_glass_easy) | 147 | Separate Impeller and captured-image paths, paint-time synchronous refresh, crop metadata, analytic shape gradients, optional batching. | Primary Flutter reference for portable capture behavior and practical lens optics. |
| [liquid_glass_widgets 1.16.1](https://github.com/sdegenaar/liquid_glass_widgets) | 815 | A broad control library, geometry/render separation, focus regions, accessibility scopes, a full Impeller renderer and a lighter Skia/web treatment. | Reference for controls, keyboard behavior, material hierarchy, and geometry caching. |
| [rdev/liquid-glass-react](https://github.com/rdev/liquid-glass-react) | 6,616 | React interaction and SVG displacement-map generation; its README explicitly limits displacement support in Safari/Firefox. | Adoption signal and API reference; its browser limitations prevent treating it as a universal renderer. |
| [shuding/liquid-glass](https://github.com/shuding/liquid-glass) | 1,225 | A compact rounded-SDF-to-displacement-map example. | A readable explanation of the essential coordinate warp. |
| [iyinchao/liquid-glass-studio](https://github.com/iyinchao/liquid-glass-studio) | 806 | SDF normals, controlled refraction, separate background blur passes, dispersion and material experiments. | Primary web reference for visual calibration and a future measured shared-blur experiment. |
| [naughtyduk/liquidGL](https://github.com/naughtyduk/liquidGL) | 1,044 | Shared rendering contexts, a WebGPU/WebGL/CSS backend chain, scene snapshots and explicitly registered dynamic content. | Reference for shared scene ownership, resource cleanup, and honest dynamic-content constraints. |

Stars measure interest. They do not establish visual accuracy, accessibility,
runtime compatibility, or frame cost. For example, the most-starred repository
above last received a push in June 2025, while both requested Flutter projects
have November 2026 activity. No performance ranking is claimed without running
the same fixtures on the same hardware.

## Findings from the actual code

### liquid_glass_easy

The inspected archive is 5.2.0. Relevant files are
`lib/src/widgets/liquid_glass_view.dart`,
`lib/src/widgets/lens/render_liquid_glass_lens.dart`, and
`lib/assets/shaders/liquid_glass_common.glsl`.

Its synchronous capture mode marks the cached image stale before painting and
lets a lens refresh the background when it paints. Its source explicitly
distinguishes this from an asynchronous after-frame capture. This reinforces
the need to test image freshness separately from the reported render path.

The common shader lifts the outward shape gradient into a convex surface normal
and refracts a viewing ray into the screen. It also keeps optical travel in
logical pixels and uses an analytic gradient that can compile on Skia.
These are useful foundations for our existing screen-space renderer.

### liquid_glass_widgets

The inspected archive is 1.16.1, with Flutter >=3.41 declared. The full renderer
uses precomputed geometry, while `adaptive_liquid_glass_layer.dart` routes
Skia/web to a lighter treatment. A pub.dev platform badge alone therefore does
not prove identical optical output across those platforms.

`glass_focus_region.dart` is a useful control-design reference.
`glass_accessibility_scope.dart` exposes overrides, but also treats high contrast
as a proxy for reduced transparency. Our API should keep those preferences
distinct and describe exactly which system signals it reads.

The render shader describes Flutter issue 188365 and uses manual bilinear
reads. The upstream issue was closed through PR 188544, but closure does not
establish availability in a release. The checked 3.44.1 and 3.47.9 sources still
expose a one-argument `ImageFilter.shader` and default the implicit texture's
sampler to nearest. The SDK audit is recorded in the evidence directory.
Our filter therefore retains a sampling-quality limitation on these SDKs.
Manual four-tap bilinear sampling remains a possible measured quality/cost
tradeoff; it was not copied unconditionally into every optical lookup.

### Web implementations

The transferable part is the displacement field: shape distance, surface
normal, bounded refraction, edge lighting, and controlled chromatic separation.
Flutter can evaluate that field in a canvas fragment shader; it does not need
CSS, a DOM clone, or SVG filter IDs.

[Aave's engineering article](https://aave.com/design/building-glass-for-the-web)
shows how the same lens field can drive SVG for ordinary DOM and WebGL for
video/canvas. It regenerates maps for shape changes and reuses them for movement.
It also describes source-size limits and distinct browser behavior. The useful
Flutter lesson is to separate material geometry from its sampling backend and
share one declared content source among related controls.

[Kube's derivation](https://kube.io/blog/liquid-glass-css-svg/) explains
height-to-normal construction and contrasts convex, concave, and lip profiles.
This helped identify that our previous normal sign described a concave bevel.
SVG scale values and channel encodings should not be copied into Flutter's
logical-pixel settings; each renderer needs an explicit unit contract.

Studio's separate blur passes are a credible future optimization candidate.
They require extra textures, shader stages, resource lifetime management, and
before/after measurements. They are not a reason to add an unmeasured blur cache
to the core package during this hardening milestone.

## Community evidence

The most useful discussion venues for this problem serve different roles:

- [r/GraphicsProgramming](https://www.reddit.com/r/GraphicsProgramming/comments/1l9abq9/)
  discusses displacement/normal maps and whether ray tracing is necessary.
- [r/FlutterDev](https://www.reddit.com/r/FlutterDev/comments/1p5tboq/made_a_liquidglass_effect_in_flutter_that_bends/)
  exposes integration problems such as transparent captured content.
- [r/webdev](https://www.reddit.com/r/webdev/comments/1s5ae5b/liquid_glass_in_the_browser_refraction_with_css/)
  points to detailed web rendering experiments and design feedback.

These discussions supplied leads. Technical decisions were checked against the
source code and Flutter's engine documentation. There is no evidence that one
community has established a universally best implementation, or that a demo
reveals Apple's private compositor.

## Changes applied to this milestone

1. Correct the convex bevel normal in both shaders. Pixel assertions require
   inward sampling at all four bevels and a stable flat center.
2. Bind the latest capture when composing the optical layer, so retained
   foreground boundaries cannot freeze the sampled generation.
3. Rotate anisotropic tap offsets in pixel space before converting to UVs.
   Equivalent scenes must produce the same result with different crop aspects.
4. Include transmission, reflection, dispersion, scatter, anisotropy, and one
   captured texel in the capture envelope.
5. Use actual rounded image dimensions for UV mapping and clamp to actual edge
   texel centers. Test fractional crops and capture scales.
6. Guard GLES Y inversion for both older Flutter engines and the top-down
   texture orientation introduced in stable Flutter 3.47, following Flutter's
   [migration guide](https://docs.flutter.dev/release/breaking-changes/opengles-render-to-texture-top-down).
7. Verify every uniform name, type, order, and bound Dart value for both paths.

Runtime fixtures, benchmark export, distinct transparency/contrast policies,
and keyboard focus feedback are now implemented; backend qualification remains
in progress. Geometry caches,
shared blur, group contour blending, and component families follow only after
their visual and performance requirements can be measured.

The production changes are independent implementations. No third-party runtime
dependency or source file has been imported. The downloaded comparison sources
are isolated in `.research/`, excluded from Git and package publication. The
Flutter packages and the first three web repositories declare MIT licensing;
liquidGL declares MIT in its README/source although GitHub's license API did
not classify its license file. Any future source reuse needs its own attribution
and license check.
