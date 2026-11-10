# Current renderer runtime evidence

All fifteen library/shader files match published source `954ea73`
(`v0.1.0-dev.1`). The isolated app checkout starts at `bc87b63`; the corrected
host-side report validator comes from `970d38f`. Exact hashes, SDK identity,
APK ABI/hash and the isolated Gradle resource override are in
[source-and-results.json](source-and-results.json).

| Target | Visual checks | Foreground endurance |
|---|---|---|
| Xiaomi M2006C3MII, Android 10, Impeller GLES | 18 passed, 43 observations | 600,640 ms; 601 samples; 120 disposals |
| Windows 11, Skia | 18 passed, 43 observations | 600,297 ms; 525 samples; 106 disposals |
| Owned Android 17/API 37 emulator, Impeller GLES | 18 passed, 43 observations | 600,536 ms; 601 samples; 120 disposals |
| Chrome 157, CanvasKit release | 18 passed, 43 observations | Not run |
| Chrome 157, skwasm release | 18 passed, 43 observations | Not run |

The native endurance validation files independently recompute signature changes,
tracked-image bounds and observed RSS ranges. Test iterations are not display
FPS; tracked image bytes are not GPU-memory measurements. These are named
foreground scenarios, not general background/resume qualification.

Two failures remain visible:

- `physical-android/soak-interrupted`: the user reported locking or switching
  apps; surface loss and a native GL-context crash followed. The foreground
  precondition was interrupted. The later foreground pass does not prove this
  lifecycle problem fixed.
- `windows/soak-timeout`: the combined run completed its visual checks, then
  stopped progressing during the soak and timed out. The old host driver
  incorrectly returned success for the incomplete report. The corrected driver
  rejects it; eight regression checks and replays of seven actual exports cover
  report validation. The separate completed retry is in `windows/soak-passed`.

PNGs are unchanged. Unique phone serials and local test-service authentication
URLs are redacted from text exports; private originals remain in `.research/`.
The repeated performance matrix is separate: all 138 measurements completed;
34 of 46 groups meet the fixed spread limits and twelve remain unstable. See
[the full report](../performance-physical-current/README.md).
