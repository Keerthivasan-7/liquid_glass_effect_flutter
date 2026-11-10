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
- [x] Run explicit example/benchmark analysis and preserve SDK/build-log artifacts for every hosted platform build job.
- [x] Run formatting, analysis and 63 package checks on Flutter 3.32.0 and 3.47.9 at `b417012`; both hosted lanes pass.
- [x] Record ten benchmark checks and seventeen independent raw-validator checks on both hosted SDK lanes, including the protocol-v7 display policy and legacy compatibility.
- [x] Prove conservative sampling bounds and semantic uniform/value bindings.
- [x] Detect deliberate refraction-sign, crop-origin, uniform-value and foreground-blur defects.
- [x] Inspect the actual published archive and confirm intended exclusions (628,400 bytes / 181 files).
- [x] Add real homepage/repository/issue links supplied by the user.
- [x] Run zero-warning dry runs locally and on both hosted SDK lanes. Earlier missing-metadata failures remain historical.
- [x] Pass hosted CI: both SDK lanes and Android, web and Windows builds, run `42791541004`.
- [x] Configure and read back all five required GitHub Actions checks on `main`, strict and enforced for administrators; block force pushes and branch deletion.
- [x] Qualify the published rotation-axis renderer on the physical phone, Windows, CanvasKit and skwasm. Human showcase review remains separate.
- [x] Refresh the library architecture graph after the publication rename: 419 nodes, 479 edges, 21 communities; synchronize root outputs and record source hashes.

## Runtime and accessibility gates

- [x] Extended Windows Skia profile capture, fallback, transform and focus contracts.
- [x] Extended Android emulator GLES capture contracts.
- [x] Current physical Xiaomi Android 10 GLES: all eighteen v5 visuals and standalone ten-minute foreground endurance on the same verified APK.
- [x] Verify separate Impeller GLES filter displacement on fixture v4.
- [x] Complete all eighteen fixture-v4 release contracts independently on CanvasKit and skwasm.
- [x] Complete current physical Xiaomi GLES v5 ten-minute checks: 600,640 ms, 120 disposals, driver exit zero and bounded retention. Preserve the interrupted attempt and its native GL-context failure.
- [x] Complete current Windows ten-minute foreground checks: 600,297 ms, 106 disposals, corrected driver exit zero and bounded retention. Reject and preserve the earlier timed-out report.
- [x] Complete current CanvasKit and skwasm release visual suites separately; actual renderer resources recorded.
- [x] Confirm a clean v4 Android emulator repeat: 10,056 frames, 120 disposals, healthy core services and no new crash-buffer entries. New native-readback harness results remain separate.
- [x] Save a short actual scrolling contract recording.
- [x] Implement explicit transparency/motion/contrast policies and opaque fallback.
- [x] Check inherited text/icon contrast, keyboard action preservation and focus feedback.
- [x] Repeat current renderer qualification on the owned Android emulator: eighteen v5 visual contracts and 600,536-ms endurance, 120 disposals, driver exit zero, bounded tracked images/RSS, final healthy services and empty crash buffer.
- [ ] Review physical-device accessibility and supported product layouts with a human reviewer.
- [x] Qualify physical Android GLES for the named phone and foreground scenarios.
- [ ] Qualify Vulkan and physical iOS/Metal before claiming them supported; other Android devices remain unverified.
- [ ] Investigate interrupted-surface/background-resume behavior before making lifecycle reliability claims.
- [ ] Test overlapping filters on physical iOS independently from capture.

## Performance gates

- [x] Implement raw exports, warm-up/window/drain, fair cases, metadata and invalid-run flags.
- [x] Preserve one accepted physical protocol-v6 ordinary-control group with three raw repetitions and independent analysis; this is not a glass or full-matrix baseline.
- [x] Record three complete profile repetitions for each of the 46 current phone cases: 138 individually valid measurements.
- [x] Independently recompute all raw statistics, hashes, spread and budget exceedances; preserve all results and limitations.
- [x] Freeze active display updates after profiling observer work; preserve Stop/invalidation, version the workload and retain the exact v6 analysis.
- [x] Qualify four focused v7 phone groups with three repetitions each and unchanged fixed limits; all twelve measurements accepted.
- [ ] Complete v7 device qualification for the remaining forty-two groups. V6 retains 34 accepted and twelve rejected groups. The full matrix gate has not passed.
- [ ] Capture representative platform memory/GPU/energy evidence where claimed.
- [ ] Approve an optimization only after equivalent visual and timing baselines.

Untested targets must remain Unverified, Unsupported, or explicitly
fallback-only. Do not describe the milestone or package as release-ready while
these required gates remain open.
