# Development handoff — 10 November 2026

Delivery deadline: **13 November 2026**. This is a development handoff, not a
production release or completion of the Verified Portable Renderer milestone.

## Included work

- Portable capture fixes, conservative optical bounds, scroll freshness,
  guarded image/picture retirement and accessibility policies from the
  recorded renderer work.
- Latest CPU rotation-axis precomputation in both shaders, without changing
  optical parameters or transmission sample counts. No measured speedup claim.
- Showcase with three functional sections: Materials, Controls and Comfort.
  Four presets, local favorites, resettable fine adjustments, light/dark mode,
  optional ambient highlights, scrollable captured decoration and comfort
  previews. Favorites and tuning are session-only.
- Complete app integration example, showcase instructions and reconciled
  performance/release notes.
- Refreshed structural library map (418 nodes, 478 edges, 20 communities) and
  future CI improvements: explicit example/benchmark analysis plus SDK and
  build-log artifacts on every platform build job. Hosted execution is pending.

## Local deliverables

Files are in `.research/artifacts/` in this workspace:

| File | Purpose |
|---|---|
| `liquid-glass-showcase-development-armv7.apk` | Final showcase profile build for 32-bit ARM Android; development signing, not a store release |
| `liquid-optics-flutter-0.1.0-dev.1-source.zip` | Library, shaders, tests, documentation and example source; no research downloads, evidence or build outputs |
| `showcase-delivery-manifest.json` | Artifact hashes, exact compiled source hashes and build SDK identity |
| `liquid-optics-flutter-dev-handoff-2026-11-10.bundle` | Offline local Git history, including source and recorded evidence, tagged `dev-handoff-2026-11-10` |

The APK uses Flutter 3.47.9. It is not a universal Android binary. It has not
been installed on the phone after the user's testing deferral. The Windows
preview was built with Flutter 3.44.1 before the final small settings/copy
cleanup; it is left open for the user and is not the final packaged executable.
The source ZIP is a development source bundle, not a published pub archive or
a source commit. Its example still resolves the library with `path: ../`.
The separate Git bundle preserves the local development revision and evidence.
It can be restored with `git clone PATH_TO_BUNDLE NEW_FOLDER`; use the quoted
absolute bundle path if it contains spaces. No remote URL is configured.

## Evidence and remaining work

Earlier visual/endurance results cover their recorded pre-axis source snapshots.
The current Android build compiles the final showcase and latest shader layout;
build success does not replace runtime qualification. Extended testing and phone
installation remain deferred. One ordinary-control timing group is accepted;
the glass timing baseline and full 46-case matrix remain open.

Local history begins at this development handoff and does not reconstruct an
original pre-change commit. There is no canonical hosted repository yet, so
source URLs, hosted CI, merge rules, a verified release tag and the publication
metadata warning remain unresolved. Physical
iOS, Vulkan and other unverified backends retain their explicit limitations.
Human accessibility/product-background review also remains open.

## Work to finish by the deadline

1. Review the showcase appearance and controls during normal development use;
   address concrete feedback without adding more optical features.
2. Keep the source package, integration instructions and final delivery manifest
   together. Create source-hosting metadata only when a real repository exists.
3. Freeze the development deliverable by 13 November and carry the remaining
   qualification items forward explicitly. Resume device work only when the
   user makes the phone available and requests it.

See [the four-day plan](FOUR_DAY_DELIVERY.md),
[milestone audit](MILESTONE_AUDIT.md) and
[release checklist](RELEASE_CHECKLIST.md) for detailed scope.
