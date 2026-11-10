# Engineering report

Updated 2026-11-10. The Verified Portable Renderer milestone is still under
qualification. [The execution record](MILESTONE_PROGRESS.md) and
[compatibility matrix](COMPATIBILITY.md) are the current status authorities.

The runtime/test results below predate CPU rotation-axis precomputation and
the showcase rewrite. The latest development source builds for Android;
additional runtime qualification and extended tests are deferred by user
direction. No speedup is claimed. See [the handoff notes](DELIVERY_NOTES.md).

## Implemented renderer

The package provides scoped capture, an independently selected Impeller
backdrop filter, and blur/tint fallback. The capture scope separates content
from functional glass, so the overlay cannot recursively capture itself.

Capture refresh now follows background-layer composition. This observes an
independently repainted scrolling child even when the scope render object does
not repaint. Clean background subtrees retain their engine layer, allowing
hover/press and other overlay-only changes to reuse the current image. The
optical layer binds the image selected in that same composition pass.

A shared footprint helper includes capped refraction, chromatic offsets,
rough/scattered transmission, reflection reach, quality stencils and anisotropy.
Bounds include an effective captured-texel guard. Shader mapping uses actual
rounded image dimensions and a 2D affine surface-to-scope transform. Interactive
scale overshoot is reserved around a stable anchor.
Crop rounding anchors texel centers to the scope at fractional capture ratios.
A 2.625-ratio checkerboard probe failed before this correction and passes
after it. Fixture v4 also prevents antialiased coordinate-grid seams from
corrupting calibration colors and records source-capture PNGs alongside output.

Images retire in independently frozen two-frame batches. Replaced optical
pictures also receive a two-frame guard, fixing a reproduced skwasm retained
scene/readback failure. Unchanged pictures are reused by image/transform
identity so guard frames cannot become an idle repaint loop.

The filter keeps logical material geometry separate from physical render-target
coordinates. Its origin is bound during composition. Qualification covers a
single untransformed window-target surface; arbitrary intermediate subpasses,
transformed filters and physical-iOS overlap remain unverified.

## Accessibility and measurement

Explicit transparency, motion and contrast policies select opaque treatment
without a shader, capture or backdrop blur. Inherited text/icon contrast adapts
to that surface. A two-tone ring exposes descendant keyboard focus and labeled
accessibility focus while preserving child actions. Explicitly styled
foreground content remains the application's responsibility.

The benchmark separates raw timing collection from its four-Hz HUD. It uses a
three-second warm-up, a timestamped measurement window, a delayed-batch drain,
bounded storage, refresh-derived budgets and native/browser JSON export.
Delayed pre-start frames cannot shorten warm-up. Automated integration uses
fully live engine frames, preserves all repetitions, and disqualifies hidden,
short, empty, timed-out or fallback-contaminated measurements.

FrameTiming distributions are work-duration proxies. Capture snapshots can
execute outside the reported frame raster duration; GPU, presentation, memory
and energy claims require platform traces. See [the protocol](PERFORMANCE.md).

## Evidence and remaining work

- The installed Flutter 3.44.1 package suite passes 55 checks, including actual
  scrolling, stripe symmetry, split-field hierarchy, background text/vector
  smoothing and sharp foreground.
- Nine benchmark checks cover timestamp windows, late batches, pre-start
  rejection, bounded storage, reproducible raw statistics and viewport/focus
  invalidation.
- Exact minimum 3.32.0 and recorded stable 3.47.9 passed formatting,
  analysis, 55 package checks and nine benchmark checks on the recorded
  pre-axis source. The only dry-run
  warning is missing real repository/homepage metadata.
- Windows passes all eighteen fixture-v5 profile contracts. CanvasKit and
  skwasm each pass all eighteen release contracts with actual WASM resources
  recorded. Android v4 image checks and its ten-minute renderer soak pass;
  older fixture results are not attributed to newer sources.
- The final Android v4 soak records 8,669 frames, 120 scope disposals and 594
  changed pixel signatures out of 601 samples. RSS after the first minute is
  215–234 MB. An unrelated emulated Bluetooth HCI crash is preserved; core
  Android services remained healthy. Entire-system zero-crash confirmation is
  separate. A subsequent clean v4 repeat completed 10,056 frames and 120
  disposals with healthy core services and no new crash-buffer entries. The
  older system_server-death run stays invalidated. Native PixelCopy v5 also
  passes all eighteen visuals; its lifecycle probe is qualified separately.
- A resumable 46-configuration Android runner preserves three-run groups.
  The independent validator recalculates raw statistics and checks declared
  repetition-spread limits; twelve validator tests reject forged summaries,
  bad timestamps, mismatched configurations, fallback, unstable repetitions
  and insufficient initial settling.
- All four required deliberate defects were caught on the recorded pre-axis
  source. An additional stale-scroll mutation is checked separately.
- The real archive dry run excludes research downloads, graphs, raw device
  evidence and benchmarks. It has one repository/homepage warning after fake
  URLs were removed. The canonical source identity is still required.

Physical Xiaomi Android 10 / Impeller GLES passes all eighteen aligned v5
visual contracts using native PixelCopy. Its standalone ten-minute endurance also passes: 5,460 test iterations, 120
disposals and 593 changed signatures in 601 samples. Tracked images peak at
918,400 bytes; RSS after the first minute ranges from 152–190 MB, and final
minute RSS remains within that range. These iterations are not display FPS.
Timing evidence remains separate. Physical iOS, Vulkan, other Android devices, macOS and Linux
remain explicitly unverified.
Hosted CI, branch protection and a reproducible release tag require a real
repository. No qualified performance improvement is claimed from the original
partial/empty Windows runs; the post-correction baseline is separate.

Protocol v6 adds sixty seconds of initial active-scene settling once per app
process and ten seconds before each repetition. One physical ordinary-control
group has three independently accepted raw repetitions. The capture group was
interrupted and invalidated by a viewport/focus change; no glass baseline or
full matrix is qualified. Later portrait safeguards and the latest optimization
belong to different snapshots.

The current structural library graph was regenerated on 10 November: 418 nodes,
478 edges and 20 communities. It includes the new private axis helper and is
excluded from the source package. Future CI now preserves SDK/build output for
all platform build jobs and explicitly analyzes the example and benchmark;
these latest workflow changes have not run.
