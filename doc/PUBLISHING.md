# First pub.dev prerelease

Published: **[`liquid_glass_effect_flutter` · `0.1.0-dev.1`](https://pub.dev/packages/liquid_glass_effect_flutter)**
on 10 November 2026. The repository is now
`Keerthivasan-7/liquid_glass_effect_flutter`; its former URL redirects.

Published source: commit `954ea73f3e2523de83667dd3b7f06f11efb5edfb`,
tag `v0.1.0-dev.1`. The registry archive is 628,400 bytes / 181 files, SHA-256
`049e510abaf4a9901efab9cee51360c94631dfae7303e9056a08c2f7399dc1f9`.
The archive checksum and 21 prepared source/documentation/screenshot hashes
match, with excluded research, evidence and build files absent. See
[the publication record](evidence/2026-11-10/pub-publication.json).

Preparation analysis reported no issues; the Windows showcase built; the final
clean-source publication dry run returned zero warnings. Google authorization
and the first upload completed successfully. The first archive retains the
repository URL valid when uploaded; GitHub redirects it to the renamed source.

The package API returned 404 for the proposed name on 10 November 2026;
`liquid_glass_effect` already exists as another author's package. A 404 does
not reserve a name. The server makes the final availability decision on upload.

The public entry point is
`package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart`.
Both shader asset keys, example/benchmark dependencies and current consumer
imports use the new package name. Compatibility entry points retain the older
development library filenames inside the new package. Historical source/SDK
evidence retains its original names and hashes.

The README includes actual Windows showcase captures: light Materials, dark
Controls and opaque Comfort. They are registered in `pubspec.yaml` and included
in the package. The explicit platform list is Android, Windows and Web; exact
backend/scenario limits remain in [COMPATIBILITY.md](COMPATIBILITY.md).

Publication preparation checks dependency resolution, analysis, a Windows
showcase build and the real archive dry run. It does not repeat phone tests or
the full performance matrix. Subsequent current-source qualification passed
eighteen visual contracts separately on the physical Android GLES phone,
Windows/Skia, CanvasKit and skwasm; foreground ten-minute endurance retries also
passed on the phone and Windows. Both hosted SDK lanes and three platform build
jobs pass, and all five checks are required on `main` with verified settings.
The full phone measurement phase collected 138 valid runs, but twelve of 46
groups fail fixed repeatability limits. That performance gate and human review
remain open; publishing this prerelease does not complete the milestone.

GitHub main contains newer qualification records and host-driver hardening.
The published archive and its README remain the immutable `954ea73` snapshot;
these later repository updates have not been republished as a new version.

Publishing requires the user's pub.dev Google account. Account sign-in is
performed by the user. Published versions cannot normally be removed or
overwritten; future corrections require a new version. See
[Dart's publication guide](https://dart.dev/tools/pub/publishing).
