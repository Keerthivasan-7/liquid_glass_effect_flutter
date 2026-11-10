# First pub.dev prerelease

Publication candidate: **`liquid_glass_effect_flutter` · `0.1.0-dev.1`**.
The repository remains `Keerthivasan-7/liquid_glass_effect`.

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
the full performance matrix. The latest renderer qualification, human review
and remaining milestone gates remain open; publishing this prerelease does
not complete the Verified Portable Renderer milestone.

Publishing requires the user's pub.dev Google account. Account sign-in is
performed by the user. Published versions cannot normally be removed or
overwritten; future corrections require a new version. See
[Dart's publication guide](https://dart.dev/tools/pub/publishing).
