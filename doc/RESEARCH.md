# Research and technical decisions

Original research: 2026-10-17. Renderer decisions updated 2026-11-09.

The [current Flutter/web comparison](REFERENCE_COMPARISON.md),
[capture contract](CAPTURE_CONTRACT.md), and [execution record](MILESTONE_PROGRESS.md)
supersede the original architecture choices below. Scoped synchronous capture
and custom render objects are now implemented. Capture is the portable primary
path; compositor filtering remains a separately qualified Impeller option.
The package depends on Flutter and Dart's `meta` annotations; no external
rendering or control library is required.

An SDK-source audit on 2026-11-09 found that both tested 3.44.1 and 3.47.9 still
expose the one-argument shader image-filter factory and nearest implicit
sampling. Issue 188365 is closed through PR 188544, but that is not a claim that
the filter-quality API is present in these releases. A manual bilinear
workaround would add sampling cost and requires its own visual/performance
comparison. The portable capture path remains the primary qualified path.

## Primary sources

1. Flutter, **Writing and using fragment shaders**: shader registration, `FragmentProgram`, supported GLSL subset, engine-owned image-filter uniforms, GLES Y inversion, program caching, and the Impeller-only limitation for shader image filters. <https://docs.flutter.dev/ui/design/graphics/fragment-shaders>
2. Flutter API, **ImageFilter.shader**: runtime support check, first `vec2`/sampler requirements, and unsupported-backend behavior. <https://api.flutter.dev/flutter/dart-ui/ImageFilter/ImageFilter.shader.html>
3. Flutter API, **BackdropFilter**: paint-order semantics, clipping requirements, and grouped-filter overlap warning. <https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html>
4. Flutter, **Impeller rendering engine**: current iOS/Android defaults and fallback behavior. <https://docs.flutter.dev/perf/impeller>
5. Blender, **Principled BSDF**: OpenPBR transmission, coat, IOR, roughness,
   dispersion, and thin-film controls. <https://docs.blender.org/manual/en/dev/render/shader_nodes/shader/principled.html>
6. Blender, **Glass BSDF**: dielectric reflection/refraction mixing and rough
   transmission. <https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/glass.html>
7. Blender, **Volume Coefficients**: per-channel absorption and scattering
   coefficients. <https://docs.blender.org/manual/en/5.3/render/shader_nodes/shader/volume_coefficients.html>
5. Flutter issue 170820: blur+shader filter composition previously changed the shader coordinate system; fixed later but avoided here to keep one predictable pass. <https://github.com/flutter/flutter/issues/170820>
6. Flutter issue 187820: reported stale previous-frame backdrop/self-feedback with overlapping shader filters on physical iOS devices. <https://github.com/flutter/flutter/issues/187820>
7. Flutter issue 188365: implicit backdrop sampler filter-quality limitation and manual bilinear trade-off. <https://github.com/flutter/flutter/issues/188365>
8. Reference repository: `whynotmake-it/flutter_liquid_glass`, Apache-2.0. Its current package uses Flutter GPU, requires Flutter 3.47, limits the real path to Impeller platforms, and emphasizes tight layer bounds and restrained animation. <https://github.com/whynotmake-it/flutter_liquid_glass>
9. pub.dev package-name check: `liquid_glass_flutter` is occupied. <https://pub.dev/packages/liquid_glass_flutter>

## Options evaluated

### `RepaintBoundary.toImage` / scene screenshots

The asynchronous screenshot approach was rejected. The implemented portable
path instead uses `OffsetLayer.toImageSync` on an isolated content layer, with
bounded capture regions and explicit image lifetime management. The overlay
cannot capture itself. Pixel tests check current-generation sampling.
Changed background layers capture before composition, including independently
repainted scroll children. Clean background layers retain their image through
overlay-only updates. Fractional capture crops align to the scope's texel grid.

### `flutter_shaders` / `AnimatedSampler`

Useful when filtering a widget's own child, but it cannot naturally sample arbitrary content painted behind a sibling. Making the scene a sampler child would entangle background and foreground composition and duplicate large subtrees.

### Custom render object

Implemented for scoped capture, bounded sample registration, optical scene
composition, and coordinate control. This does not remove engine/backend
qualification requirements.

### `BackdropFilter(ImageFilter.shader)`

Retained as an explicit Impeller-only option. Capability checks establish API
availability; separate rendered-pixel tests must establish correct geometry,
sampling, and foreground sharpness on each backend.

## Optical model

The shader is a screen-space approximation, not a physically complete dielectric simulation. A rounded SDF describes distance to the shape boundary. Its gradient supplies an outward edge normal. A smooth edge mask controls displacement, keeping the center comparatively stable. Public refraction strength and thickness scale displacement, while `maxDisplacement` and safe UV padding bound sampling.

Fresnel uses Schlick's approximation with the dielectric F0 derived from the
configured IOR. The shaders include anisotropic rough reflection, optional RGB
dispersion, Beer–Lambert-style absorption, coat and thin-film approximations.
Quality selects the spatial sampling stencil; dispersion is controlled
separately. These remain screen-space approximations, as described in
[the optical model](PHYSICS_MODEL.md). Final output is premultiplied.

## Dependency decision

The only non-SDK dependency is Dart's `meta` annotation package. Flutter 3.32 is
the declared floor. Exact minimum and current stable checks are recorded in the
execution log; a lower floor requires its own verification.
