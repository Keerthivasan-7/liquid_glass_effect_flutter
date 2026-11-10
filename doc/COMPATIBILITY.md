# Compatibility and renderer contract

Updated 2026-11-10. Current results include the CPU-computed anisotropy axis
and package rename. All fifteen renderer source files match the published
`v0.1.0-dev.1` source; see [source identity and results](evidence/2026-11-10/runtime-current/source-and-results.json).
Verification covers the named SDK, backend, and scenarios.
It does not establish every device on that platform. Raw evidence is retained
in the source workspace under `doc/evidence/` and excluded from the pub archive.

| Target/backend | Capture | Filter | Evidence and limits |
|---|---|---|---|
| Windows 11 / Skia | Verified, fixture v5 | Unsupported by the engine | Flutter 3.47.9 profile, OS build 26300, 1582x853 app view, DPR 1.25, 144 Hz. [All 18 contracts](evidence/2026-11-10/runtime-current/windows/contracts/runtime.json); filter verifies fallback. [Ten-minute foreground endurance](evidence/2026-11-10/runtime-current/windows/soak-passed/validation.json): 600,297 ms, 106 disposals, bounded tracked images. Earlier timed-out run is preserved and rejected. |
| Android 17 API 37 emulator / Impeller GLES | Verified, fixture v5 | Verified single translated window-target surface | Flutter 3.47.9, project-owned AVD, sdk_gphone16k_x86_64, 1080x2400, DPR 2.625, 60 Hz. [All 18 current contracts](evidence/2026-11-10/runtime-current/android-emulator/contracts/runtime.json); actual GLES backend recorded. [Ten-minute endurance](evidence/2026-11-10/runtime-current/android-emulator/qualification/validation.json): 600,536 ms, 120 disposals and bounded tracked images/RSS. [Final health](evidence/2026-11-10/runtime-current/android-emulator/health-after.json): package/activity services present, crash buffer empty. Functional emulator evidence, not device performance. Earlier failures remain historical. |
| Physical Android 10 / Impeller GLES | Verified, fixture v5 | Verified single untransformed window-target surface | Xiaomi M2006C3MII, ARMv7, MT6765 / PowerVR GE8320. Flutter 3.47.9 profile, 720x1504 portrait app view, DPR 2, 60 Hz. [All 18 native PixelCopy contracts](evidence/2026-11-10/runtime-current/physical-android/contracts/runtime.json) and [source/APK identity](evidence/2026-11-10/runtime-current/source-and-results.json). [Ten-minute foreground endurance](evidence/2026-11-10/runtime-current/physical-android/soak-passed/validation.json): 600,640 ms, 120 disposals, bounded tracked images. An interrupted attempt after the user locked/switched apps produced a native GL-context crash and remains a failure. Background/resume behavior and timing are separate gates. |
| Android / Impeller Vulkan | Unverified | Unverified | Must be qualified independently from GLES. |
| Android / Skia | Unverified | Unsupported by the engine | No current runtime result. |
| Physical iOS / Impeller Metal | Unverified | Unverified | Capture, scrolling, and overlapping filter tests require physical hardware. |
| Web / CanvasKit | Verified, fixture v5 | Unsupported by the engine | Flutter 3.47.9 release, headless Chrome 157, DPR 1, 60 Hz reported. [All 18 contracts](evidence/2026-11-10/runtime-current/web-canvaskit/runtime.json); actual CanvasKit WASM resources recorded. |
| Web / skwasm | Verified, fixture v5 | Unsupported by the engine | Flutter 3.47.9 release, headless Chrome 157, DPR 1, 60 Hz reported. [All 18 contracts](evidence/2026-11-10/runtime-current/web-skwasm/runtime.json); actual skwasm resources and cross-origin isolation recorded. Prior 3.44.1 regression evidence is retained separately. |
| macOS / Linux | Unverified | Capability-dependent, unverified | No release support claim without runtime evidence. |

The expanded suite checks four-edge convex sampling, clipping, sharp composited
foreground, fractional crop/scale, anisotropy independent of crop aspect,
current content generations, failure downgrade, resize/DPR, shared-crop
movement, affine capture mapping, opaque accessibility modes, reduced motion,
keyboard/accessibility focus and child activation. It also selects filter
explicitly and checks either real displacement on Impeller or fallback on
other backends. A capability flag alone does not pass that optical check.
Fixture v3 adds calibrated stripe axis symmetry/stable-center checks,
light/dark material hierarchy, background text/vector smoothing, and actual
scrolling through an independently repainted background layer.
Fixture v4 preserves the same assertions, adds explicit fractional-ratio crop
invariance, fits the resize scene within a 400-logical-pixel viewport, and
exports source images. The coordinate backdrop disables rectangle antialiasing
to avoid translucent calibration seams during downsampling. A clean v4 Android
repeat completed 600,532 ms, 10,056 frames and 120 disposals with bounded
retention, healthy core services and no new crash-buffer entries; see
[the repeat validation](evidence/2026-11-09/android-v4-bluetooth-off/validation.json).
Only the project-owned emulator's Bluetooth was disabled. Earlier failures
remain preserved. Fixture v5 replaces the coordinate field with two equivalent
opaque axis gradients, preserves calibration size on narrow screens, and adds
Android presented-surface readback. Its results are recorded separately.
Native views keep the fixture's logical scale and align its centered origin to
physical pixels. Logical probes sample pixel centers. Failed earlier runs with
fit-to-screen scaling or fractional physical origins remain preserved; optical
tolerances were not loosened. The phone's earlier offscreen engine readback
stalled before assertions, while native PixelCopy completed. The user confirmed
the earlier USB removal was intentional; it is not a device-crash result.

Status vocabulary:

- **Verified:** the stated path and scenarios passed on the named target.
- **Verified with fallback:** runtime passed with the documented degraded
  treatment; it does not verify refraction.
- **Unverified:** no matching runtime evidence for that target/scenario.
- **Unsupported:** the engine/API does not provide that path.

## Paths and coordinates

`auto` prefers scoped capture, then an engine-supported Impeller filter, then
fallback. Each path can be selected explicitly for qualification.

- Capture samples the declared content plane, excluding the glass overlay.
  Optics bind the current image during scene composition, so a retained
  foreground cannot freeze an older generation. A changed background layer
  captures before composition even when its scope render object did not paint;
  clean background layers remain retained for overlay-only changes.
- Filter samples the compositor backdrop. Its surface geometry is in logical
  pixels; its engine-owned texture size and fragment positions are physical
  render-target coordinates. The surface origin is updated during composition,
  including retained translations. Qualification currently covers a single,
  untransformed window-target surface. Rotation/scale, intermediate filtered
  subpasses, cropped readbacks, and overlapping filters remain unverified; use
  scoped capture for qualified affine mapping. Filter tests read the whole
  view at its device ratio to preserve the live target's coordinate system.
  The tested SDKs also retain nearest sampling for the implicit filter texture;
  a closed upstream filter-quality issue does not remove that release-specific
  limitation. Fine displaced edges can alias.
- Fallback normally uses clipped blur/tint. Reduced transparency or high
  contrast uses an opaque surface without shader, capture, or backdrop blur.
  Foreground content remains sharp.

Capture failure disables capture for that scope, clears its image, and reports
diagnostics once. A newly created scope can attempt capture again.
`onRenderPathChanged` reports the concrete selected path.

## Resources and engine details

- The [capture contract](CAPTURE_CONTRACT.md) defines conservative bounds,
  actual image dimensions, and 2D affine mapping. Perspective is unqualified.
- All active sampling regions share one rectangular union; widely separated
  controls can approach full-scope capture cost.
- Current/retained/peak RGBA estimates describe scope images, not GPU counters.
  Retired image batches receive independent two-frame guards.
- Replaced optical pictures receive a two-frame guard as well. Picture reuse
  keys include the current image and affine mapping, preventing idle retirement
  frames from creating a continuous repaint loop. This fixed a reproduced
  skwasm retained-scene/readback disposal failure on 3.44.1 and 3.47.9.
- GLES render targets changed orientation in stable Flutter 3.47. Both shaders
  use the [documented version-aware guard](https://docs.flutter.dev/release/breaking-changes/opengles-render-to-texture-top-down).
  Both older and newer engine application pixel checks pass; final v4 lifecycle
  checks pass with the explicit unrelated-service caveat above.
- Overlapping filters do not share a BackdropKey; grouped filter optimization
  is unsuitable for overlapping members.
- [Flutter issue 187820](https://github.com/flutter/flutter/issues/187820)
  reported physical-iOS feedback. It was closed after awaiting a response;
  closure does not establish a fix. Physical-iOS overlap remains unverified.
