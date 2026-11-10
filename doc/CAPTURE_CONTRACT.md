# Capture sampling contract

The content plane is captured independently of the functional overlay. Its
background layer refreshes the image just before changed content is composed;
the surface's optical layer then binds that image in the same composition.
An independently repainted scrolling child is observed even when the scope
render object does not repaint. Clean background subtrees retain their engine
layer, so overlay-only changes reuse the image. Snapshot composition is guarded
against reentry. Sharp children keep Flutter's normal painting/compositing
lifecycle.

## Units and coordinate mapping

| Value | Unit and meaning |
|---|---|
| Surface size / fragment position | Local logical pixels of the glass widget. |
| Capture rectangle | Logical pixels in the scope's content plane. |
| Effective capture ratio | Scope pixelRatio (or DPR) multiplied by qualityScale. |
| Image pixel size | Actual integer image width/height returned by toImageSync. |
| Shader scope size | Actual image pixel dimensions divided by effective ratio. |
| Scope origin | Transformed surface origin minus the capture rectangle origin. |
| Surface-to-scope matrix | Four coefficients for the local-to-scope 2D affine transform. |

Using the actual image extent preserves scale when the requested crop times its
ratio rounds up to fractional output pixels. Refraction, chromatic offsets,
reflection offsets, and anisotropic taps all pass through the same affine map.
Rotation/stretching happens in local pixel units before UV normalization.
Perspective mapping is not included in this contract.

## Conservative envelope

`lib/src/rendering/capture_footprint.dart` is the Dart authority. Its equations
match the shader's current sampling model:

- Each refracted color vector is bounded by `1.3 * maxDisplacement`, including
  the largest bevel multiplier. RGB dispersion changes IOR, not that cap.
- Artistic chromatic reach adds `chromaticAberration * shortestSide`.
- Scatter includes blur, roughness squared, thickness, and scattering, capped
  at 32 local pixels. Reflection has its own radius capped at 24.
- Stencil reach is 0, 0.38, or 0.92 times the relevant radius for performance,
  balanced, or ultra quality.
- The anisotropy matrix has maximum singular value
  `1 + abs(anisotropy) * 1.75`. Rotation cannot enlarge that radial bound.
- Reflection-center reach is bounded by 0.85 of the refracted reach plus
  0.24 of the transmission scatter radius.

The triangle inequality bounds each sample center plus its tap. Take the larger
transmission/reflection reach, inflate the local surface by it, and transform
that rectangle into scope coordinates. Add one scope logical pixel plus one
captured texel for raster/filter safety. This also covers nonuniform affine
scale and rotation without treating a local distance as a scope distance.

Interactive surfaces reserve the entire hover/press scale envelope around an
anchor outside the animated scale. The bound includes the release curve's
overshoot (maximum reserved scale 1.011). Overlay-only scale changes therefore
reuse a static content image. Moving or resizing the anchor still updates the
capture bounds. A regression test covers the complete hover/press animation.

The scope unions client bounds, rounds outward on the effective captured-texel
grid anchored at the scope origin, and clips to its content plane. Logical-only
rounding shifts texel centers at fractional ratios; a 2.625-ratio checkerboard
regression reproduced that crop-dependent difference and passes with grid
alignment. Expanding a crop must preserve the same sampling lattice.
At a genuine content-plane boundary, unavailable outside content is clamped to
the nearest valid texel center. A smaller crop must not introduce another
clamping band or change the requested material scale.

## Evidence

Property tests cover quality stencils, anisotropy signs/rotations, narrow and
large surfaces, configuration extremes, fractional bounds, and noninteger
DPR/quality products. Pixel checks cover mapping, four-edge refraction,
foreground sharpness, all silhouettes, crop-aspect independence, live content,
resize/DPR, affine transforms, shared-crop movement, and failure fallback.

Four deliberate mutations were detected: reversed refraction, shifted crop
origin, incorrect Dart uniform value, and blurred foreground. The affine probe
also failed against the old translation-only mapping before the correction.
An additional mutation that suppressed retained-scroll recapture was also
detected. Runtime qualification is tracked separately in
[COMPATIBILITY.md](COMPATIBILITY.md).

Optical pictures are keyed by image identity and the surface-to-scope affine
map. Unchanged scenes reuse their picture; replaced/disposed pictures receive
a two-frame retirement guard. A skwasm readback regression exposed immediate
picture disposal through a retained scene. The full browser suite passes with
the guard; retirement frames do not create an idle repaint loop.
