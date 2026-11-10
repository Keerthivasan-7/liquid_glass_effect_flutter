# Release readiness checklist

Updated 2026-11-10. Evidence and incomplete gates are recorded in
[MILESTONE_PROGRESS.md](MILESTONE_PROGRESS.md). A prior smoke run does not
qualify newer shader or lifecycle changes.

## Source identity and packaging

- [ ] Confirm the final pub.dev name and canonical source repository.
- [x] Remove fake homepage/repository/issue URLs.
- [x] Include BSD-3-Clause license and independent-reference research records.
- [x] Exclude research downloads, CI, raw evidence, graphs and build outputs from the package.
- [ ] Inspect the final package archive and resolve dry-run warnings truthfully.
- [ ] Establish a reproducible source commit/tag.
  The local `dev-handoff-2026-11-10` snapshot preserves development source;
  a verified release commit/tag and canonical hosted repository remain open.

## Automated engineering gates

- [x] Implement minimum 3.32.0 and current stable CI lanes and build smoke jobs.
- [x] Prepare explicit example/benchmark analysis and SDK/build-log artifacts for every platform build job; hosted execution remains open.
- [x] Run final formatting, analysis and 55 package checks on Flutter 3.32.0 and 3.47.9; source hashes match.
- [x] Record nine benchmark checks on both SDKs and twelve independent raw-validator tests before the latest renderer change.
- [x] Prove conservative sampling bounds and semantic uniform/value bindings.
- [x] Detect deliberate refraction-sign, crop-origin, uniform-value and foreground-blur defects.
- [x] Inspect the real 366-KB archive and confirm intended exclusions.
- [ ] Resolve the one missing real repository/homepage warning; both SDK dry runs exit 65 for that warning.
- [ ] Run hosted CI and configure required checks once a real repository exists.
- [ ] Qualify the final rotation-axis/shader and showcase source; builds alone do not close this gate. Extended runs deferred by user direction.
- [x] Refresh the library architecture graph after the axis-helper change: 418 nodes, 478 edges, 20 communities; synchronize root outputs and record source hashes.

## Runtime and accessibility gates

- [x] Extended Windows Skia profile capture, fallback, transform and focus contracts.
- [x] Extended Android emulator GLES capture contracts.
- [x] Physical Xiaomi Android 10 GLES: all eighteen v5 visuals and standalone ten-minute endurance on the same verified APK.
- [x] Verify separate Impeller GLES filter displacement on fixture v4.
- [x] Complete all eighteen fixture-v4 release contracts independently on CanvasKit and skwasm.
- [x] Complete physical Xiaomi GLES v5 ten-minute renderer/disposal checks: 5,460 test iterations, 120 disposals, driver exit zero and bounded retention. Preserve all earlier failed attempts.
- [x] Confirm a clean v4 Android emulator repeat: 10,056 frames, 120 disposals, healthy core services and no new crash-buffer entries. New native-readback harness results remain separate.
- [x] Save a short actual scrolling contract recording.
- [x] Implement explicit transparency/motion/contrast policies and opaque fallback.
- [x] Check inherited text/icon contrast, keyboard action preservation and focus feedback.
- [ ] Review physical-device accessibility and supported product layouts.
- [ ] Qualify physical Android, Vulkan and physical iOS/Metal before claiming them supported.
- [ ] Test overlapping filters on physical iOS independently from capture.

## Performance gates

- [x] Implement raw exports, warm-up/window/drain, fair cases, metadata and invalid-run flags.
- [x] Preserve one accepted physical protocol-v6 ordinary-control group with three raw repetitions and independent analysis; this is not a glass or full-matrix baseline.
- [ ] Record at least three complete profile/release repetitions for each product case.
- [ ] Recompute statistics from raw samples and report run spread and limitations.
- [ ] Capture representative platform memory/GPU/energy evidence where claimed.
- [ ] Approve an optimization only after equivalent visual and timing baselines.

Untested targets must remain Unverified, Unsupported, or explicitly
fallback-only. Do not describe the milestone or package as release-ready while
these required gates remain open.
