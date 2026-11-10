# Visual excellence: implementation plan

Updated 10 November 2026 from the current working tree and the supplied audit.
Delivery priority: the appearance, motion and usefulness of the material, followed
by an extensible animation/effects library. Existing portability work remains a
foundation. The next visible milestone is a polished scene with convincing
coalescing controls, rather than another long benchmark campaign.

## Implementation update, 10 November

The development example now opens in Optics Studio. The current source
implements independent vibrancy, continuous lighting input, accessible
controls, a capture-backed union of up to four capsules, an elastic selection
indicator and two independently timed wave packets. The stage supports
scrubbing, replay, zoom and a large-text preview. See the
[runtime recording](../assets/showcase/studio-motion.webp) and the
[integration example](INTEGRATION_GUIDE.md#joined-controls-in-the-development-checkout).

The first cluster API takes explicit member geometry in group coordinates.
It covers axis-aligned capsules sharing one material. Independent rotations
per member, arbitrary descendant registration, joined filter-backend optics,
projected lighting and the broader effects catalog remain follow-on work.
The checked-in graph now covers the new Dart library files.

The following audit describes the starting point for this implementation.

## 1. What existed at the start of the audit

The working tree contains new studio highlights, tint/vibrancy changes,
five-sample dispersion, an analytic ripple normal, a meniscus-like profile,
lighting-controller wiring, and card/button/navigation components. These are
uncommitted changes relative to main `4d9fd31`. Previous published-renderer
runtime evidence does not automatically qualify these modified shaders.

| Area | Verified from current source | Remaining work |
|---|---|---|
| Lighting | Controller values reach capture/filter bindings and overlay configuration. | Preserve tilt magnitude, define radians, handle neutral/nonfinite input, and demonstrate continuous motion. |
| Ripples | Radial cosine term perturbs the optical normal. | `u_time` comes from the light-animation controller, which is stopped by default. Add independent event time and overlapping impulses. |
| Refraction depth | A multiplier lengthens travel after a single `refract` call. | This is not a solved front/back-interface ray traversal. Implement an actual back-surface intersection and exit refraction before using that label. |
| Meniscus/TIR | Exponential profile adjustment and grazing-angle brightening. | Derive normals consistently from the height profile; distinguish an artistic rim from internal-ray critical-angle physics. No Young–Laplace solver exists. |
| Dispersion | Five backdrop samples with interpolated red/blue offsets and a hash perturbation. | This is not continuous spectral integration or demonstrated blue noise. Calibrate wavelength-dependent IOR and color reconstruction if those are intended claims. |
| Group behavior | Shared pointer/velocity field. | No shared silhouette, union normal field, bridge or merged material pass. |
| Components | Card, button and navigation wrappers exist. | Button keyboard behavior, motion preferences, large text, selection semantics, foreground policy and edge cases need completion. |
| Showcase | Existing Materials/Controls/Comfort application. | New components and visual upgrades need a coherent, visible comparison scene. |

Apple already provides interactive, morphing glass and container unions. The
opportunity is a distinctive, controllable implementation that works well in
Flutter, not an unsupported claim that Apple cannot merge controls. See
[Apple's custom-view guide](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
and [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/).

The current implementation is a screen-space, physically inspired UI renderer.
[OpenPBR](https://academysoftwarefoundation.github.io/OpenPBR/) and
[PBRT's dielectric model](https://pbr-book.org/4ed/Reflection_Models/Dielectric_BSDF)
are valuable references; borrowing individual terms does not establish full
OpenPBR conformance, path-traced realism, or energy conservation.

## 2. Visual target and how to judge it

Build a single art-directed studio that makes improvements visible in seconds:

- A quiet, clear resting surface with broad controlled highlights and a clean
  silhouette. Rainbow separation is restrained unless a prism style is selected.
- Touch creates a localized response that propagates and settles. Highlight,
  shape and refracted content react as parts of the same material.
- Nearby controls join through a continuous optical bridge, without a doubled
  rim, independent overlapping highlights or distorted foreground labels.
- A selection indicator stretches, catches up and settles into its destination.
- Buttons, labels and focus states remain readable on white, black, saturated,
  photographic and mixed text/image backgrounds.

Judge material depth, edge quality, highlight control, motion coherence,
foreground legibility and composition separately on a five-point review sheet.
Use matched backgrounds, size and movement when comparing references. Record
the reviewer's preferences; do not infer visual superiority from shader feature
counts, stars, test counts or an attractive unrelated screenshot.

Use [Mobbin](https://mobbin.com/) for layout, hierarchy and interaction-flow
references. Its public page was inspected; a paid-screen collection was not
reviewed. Use actual runtime captures for this package's showcase. Generated
mockups or source-code inspection cannot establish the rendered appearance.

## 3. Work package A — correct the current visual foundation

Files: both fragment shaders, `capture_footprint.dart`, controller/component
files and their focused regressions.

1. Correct studio-softbox interpolation. Replace descending `smoothstep` edges
   with the complement of an ascending interpolation. GLSL leaves reversed
   edges undefined; see [the Khronos reference](https://raw.githubusercontent.com/KhronosGroup/OpenGL-Refpages/main/gl4/smoothstep.xml).
2. Make tint continuous at zero opacity. Blend the linear/soft-light response
   using the requested tint amount, so a nearly transparent color approaches
   the untinted image. The audited code produced a 29-channel-level jump.
3. Expand the transmission footprint for spectral jitter. The new red/blue
   taps multiply the complete displacement by up to 1.09 before adding the
   scatter stencil. Protect that full reach and leave reflection reach tied to
   its separate sampling equation.
4. Separate vibrancy from the legacy saturation control. Give the curve an
   explicit strength/identity case, preserve neutral ramps, and avoid clipped
   midtones or colored halos. Tune it against real backgrounds.
5. Make the lighting controller accept radians with a documented neutral pose.
   Retain input magnitude, interpolate smoothly through the center and reject
   nonfinite values. Keep sensor packages outside the core dependency set.
6. Finish button and navigation state handling: keyboard activation, focus,
   disabled-during-press reset, reduced-motion policy, large text, selected
   semantics, index bounds, and foreground colors on explicit opaque surfaces.

Done means: identity/continuity and sampling regressions pass, new controls are
usable, and a short capture demonstrates clean light/dark/photo results. Items
1–3 have source corrections and regressions in this worktree. All 31 focused
checks and the 86-test package integration run pass; analysis is clean. See the
[source-scoped results](evidence/2026-11-10/visual-foundation-audit/README.md).
Remaining items are planned work, and native appearance review remains open.

## 4. Work package B — create the comparison studio immediately

Files: `example/lib/main.dart`, a small `example/lib/studio/` scene, example
assets and the showcase instructions.

1. Add a Studio destination using the new card, button and navigation components.
2. Provide five background choices and Clear, Satin and Prism looks. Use
   deliberate spacing and restrained typography rather than a wall of sliders.
3. Keep material, illumination and motion controls separate. Expose only the
   controls needed to judge the active experiment; put numerical diagnostics
   behind a developer panel.
4. Add fixed camera/lighting/configuration presets and reset/replay controls.
   A reference still from a frozen source and a current runtime pane must be
   labeled accurately; do not call different live presets a before/after test.
5. Capture a short interaction recording showing resting state, press/drag,
   release, navigation selection and large text. Review actual output before
   adding another optical feature.

Done means: the user can open one screen and judge the improvement without
reading code. Keep composition and material treatments consistent across the
scene. This screen becomes the ongoing visual review surface for later work.

## 5. Work package C — genuine coalescence

Files: `liquid_glass_group.dart`, `liquid_glass.dart`, a geometry registry,
group renderer/shader, capture-footprint support and the Studio scene.

1. Extend group behavior through an opt-in merge configuration. Preserve its
   existing gesture-sharing behavior and the existing independent-surface API.
2. Register each member's stable ID, shape, local bounds, transform, material
   compatibility and visibility. Separate geometry changes from pointer energy
   so geometry updates do not rebuild foreground children.
3. Convert member geometry into one group coordinate system. Establish units
   in logical pixels for blend radius, normals and capture bounds. Validate
   transforms explicitly; stage rotated/nonuniform/affine support with measured
   distance/normal behavior rather than silently treating bounds as rectangles.
4. Implement a shared signed field using a compact polynomial smooth minimum:
   `h = clamp(0.5 + 0.5 * (b-a)/k, 0, 1)` and
   `d = mix(b, a, h) - k*h*(1-h)`; use ordinary minimum when `k == 0`.
   The pasted audit's logarithmic expression is exponential smooth minimum,
   not polynomial smooth minimum. Use a stable reduction order for multiple
   members and inspect changing topology for seams.
5. Derive the normal from the shared field and height profile, then shade the
   merged material once. Union clipping alone with independently shaded lenses
   produces doubled rims and is not the intended result.
6. Keep foreground widgets outside the material pass, with their own original
   actions and semantics. The optical bridge is decorative and must not invent
   a large invisible hit target between unrelated controls.
7. Include bridge expansion, refraction, dispersion, scattering and raster
   fringe in group paint/capture bounds. Capture the declared background plane;
   never capture the group's own glass, shadows, caustics or foreground.
8. Define incompatible material and capacity behavior explicitly. A limit must
   not silently drop members. Continue toward the complete promised geometry
   scope; an initial two-member prototype is a development step, not completion.

Start the visible prototype with two moving pills, then extend to three members,
separation/rejoining, mixed sizes and the navigation indicator. Later complete
the supported affine cases and backend behavior. On paths that cannot yet
render a union, retain a clearly labeled independent treatment; do not advertise
that as verified coalescence.

Done means: the connecting neck has continuous highlights and refraction,
internal rims disappear, foreground remains sharp, separation has no popping,
and the supported geometry/backend matrix is recorded from runtime output.

## 6. Work package D — motion with a real event clock

Files: a small interaction driver, group/widget bindings, uniform manifests,
both shaders and Studio playback controls.

1. Add elapsed interaction time in seconds independently of light rotation.
   A tap must animate with `animateLight: false`. Update the uniform contract
   and bindings together instead of repurposing an existing slot silently.
2. Model an impulse with origin, start time, amplitude and damping. Add a small
   bounded impulse collection for successive taps so a new touch does not
   teleport every existing wave to the latest pointer.
3. Use an analytic, damped wave packet first, with a causal advancing envelope.
   Differentiate its height for normals. Name it as an analytic approximation;
   boundary-reflecting shallow-water dynamics require additional state/solving.
4. Drive spring displacement, optical normal and highlight response from the
   same interaction state. Preserve child gesture ownership, drag cancellation
   and immediate response to a second interaction during release.
5. Stop ticking after energy decays. Apply reduced-motion behavior consistently
   to the material and wrapper transforms; keep controls responsive when still.

Done means: a still light source can accompany an outward-moving tap response;
overlapping taps remain independent; release settles without discontinuities;
and reduced motion produces a quiet, usable result.

## 7. Work package E — deepen optics deliberately

1. Derive the bevel/meniscus normal from the chosen height profile, not from an
   unrelated brightness term. Give artists stable profile presets.
2. Implement front-surface refraction, a defined back-surface intersection and
   exit refraction, with consistent IOR conventions and a bounded footprint.
   Evaluate TIR from the internal ray and interface normal. Keep artistic rim
   glow as a separate optional treatment.
3. If pursuing spectral dispersion, choose wavelengths and IORs explicitly,
   reconstruct linear color with documented weights, normalize neutral input,
   and compare high-contrast edges. Five interpolated offsets do not establish
   a continuous spectrum; a spatial hash does not establish blue-noise sampling.
4. Add a projected light/shadow pass underneath the glass, excluded from its
   capture source. Start with a controlled screen-space caustic approximation
   with explicit gain/extent. Full scene caustics need geometry/lighting data
   that a single captured background image does not contain.
5. Balance clear, frosted and prism styles individually. Stronger brightness,
   dispersion and deformation are not automatically a better default material.

Done means: the change improves the matched Studio views and remains coherent
in motion. Publish its actual model and limits. Do not describe a UI effect as
a full Blender/Cycles path tracer or guarantee arbitrary text contrast.

## 8. Work package F — turn the material into a library

Complete button, card, navigation and segmented selection before expanding into
slider, switch, menu, modal and a button-to-panel transition. Each control needs
keyboard/touch semantics, responsive labels, focus return and interruption-safe
motion alongside its visual design.

Extract reusable material styling, shape fields, interaction drivers and
transition coordination after the first two real controls exercise them.
Keep clear/crystal/frosted appearances separate from gel/ripple/morph motion.
The future effects library can then add prism, gel, ink and related treatments
without turning the glass shader into one universal collection of unrelated
branches. Preserve the published package name and provide migration paths for
public configuration changes.

Done means: several distinctive controls reuse the same material/motion rules,
developers can reproduce showcased looks with small examples, and every public
effect has a clear capability description and a useful quiet/reduced mode.

## 9. Delivery sequence through 13 November

This retains the existing deadline; it does not estimate the entire long-term
effects library as a three-day job.

| Order | Concrete deliverable | Review decision |
|---|---|---|
| First | Foundation corrections and Studio with the current components | Are clear/frosted/prism treatments visibly coherent and readable? |
| Next | Shared two-pill union, then multi-member geometry and joined navigation selection | Is there one material across the bridge, without duplicated borders? |
| Next | Independent ripple time, interruptible release and reduced motion | Does the response look intentional with static lighting? |
| By 13 Nov | A polished hero scene, short real-runtime recording, usable component examples and an accurately scoped development release candidate | What is actually ready to show and ship, and what remains experimental? |
| Following milestone | Full supported coalescence geometry/backend scope, deeper optics, projected light and the broader animation/effects catalog | Preserve the complete intended end state; do not relabel the prototype as the finished library. |

Use focused shader/pixel/interaction checks while developing. Run the complete
automated suite at coherent integration points. Schedule longer device timing
campaigns when needed for a measured regression or release gate; they are not
the daily visual-development loop. The recorded native backgrounding failure
remains a release concern and must be investigated before lifecycle claims.

## 10. Research sources and limits

- [Apple custom glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views): container, union, interaction and morphing behavior.
- [Apple material design](https://developer.apple.com/videos/play/wwdc2025/219/): adaptive layering, context and coordinated motion; proprietary internal implementation is not public proof of a particular blend formula.
- [OpenPBR specification](https://academysoftwarefoundation.github.io/OpenPBR/), [PBRT dielectrics](https://pbr-book.org/4ed/Reflection_Models/Dielectric_BSDF): physical reference and terminology.
- [Khronos smoothstep](https://raw.githubusercontent.com/KhronosGroup/OpenGL-Refpages/main/gl4/smoothstep.xml): defined interpolation behavior.
- [liquid_glass_easy](https://github.com/AhmeedGamil/liquid_glass_easy), [liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets): portable rendering, controls and API references. Do not repeat the pasted audit's broad defect rankings without matched reproduction.
- [Liquid Glass React](https://github.com/rdev/liquid-glass-react): elastic interaction and approachable controls; its README documents partial Safari/Firefox displacement support.
- [Liquid Glass Studio](https://github.com/iyinchao/liquid-glass-studio): material exploration and a useful visual-laboratory presentation model.
- [Mobbin](https://mobbin.com/): design-reference workflow; no claim of reviewing its private collections.

Earlier version-pinned source research remains in `doc/REFERENCE_COMPARISON.md`.
This plan distinguishes inspected source, third-party descriptions, proposed
implementation and rendered verification. The existing code graph predates the
new components and must be refreshed when this working-tree implementation is
settled; it is not evidence that the new features have already been qualified.
