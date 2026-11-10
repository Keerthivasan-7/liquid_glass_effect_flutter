# Release readiness checklist

Updated 2026-11-10. Evidence and incomplete gates are recorded in
[MILESTONE_PROGRESS.md](MILESTONE_PROGRESS.md). A prior smoke run does not
qualify newer shader or lifecycle changes.

Public prerelease `0.1.0-dev.1` was published on 10 November 2026. The remaining
verification gates below still apply to completion of the renderer milestone.

## Source identity and packaging

- [x] Confirm the renamed canonical source repository: `Keerthivasan-7/liquid_glass_effect_flutter`.
- [x] Register `liquid_glass_effect_flutter` and publish `0.1.0-dev.1`.
- [x] Remove fake homepage/repository/issue URLs.
- [x] Include BSD-3-Clause license and independent-reference research records.
- [x] Exclude research downloads, CI, raw evidence, graphs and build outputs from the package.
- [x] Inspect the final prerelease archive and resolve dry-run warnings: zero warnings; registry archive 628,400 bytes / 181 files, with private files excluded.
- [x] Establish a reproducible prerelease source commit/tag: `954ea73`, `v0.1.0-dev.1`; archive checksum and 21 prepared-file hashes match. This is not proof of runtime qualification.

## Automated engineering gates

- [x] Implement minimum 3.32.0 and current stable CI lanes and build smoke jobs.
- [x] Prepare explicit example/benchmark analysis and SDK/build-log artifacts for every platform build job; hosted execution remains open.
- [x] Run final formatting, analysis and 55 package checks on Flutter 3.32.0 and 3.47.9; source hashes match.
- [x] Record nine benchmark checks on both SDKs and twelve independent raw-validator tests before the latest renderer change.
- [x] Prove conservative sampling bounds and semantic uniform/value bindings.
- [x] Detect deliberate refraction-sign, crop-origin, uniform-value and foreground-blur defects.
- [x] Inspect the real 366-KB archive and confirm intended exclusions.
- [x] Add real homepage/repository/issue links supplied by the user.
- [x] Run the publication-candidate dry run on Flutter 3.44.1: zero warnings. Earlier SDK dry runs exited 65 for the then-missing source metadata; final minimum/latest SDK qualification remains separate.
- [ ] Run hosted CI and configure required checks. Upload commits skipped automated suites at the user's request.
- [ ] Qualify the final rotation-axis/shader and showcase source; builds alone do not close this gate. Extended runs deferred by user direction.
- [x] Refresh the library architecture graph after the publication rename: 419 nodes, 479 edges, 21 communities; synchronize root outputs and record source hashes.

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
