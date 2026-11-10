# Integrating the development package

This guide covers the development checkout. Use Flutter 3.32
or later. The first prerelease is published on
[pub.dev](https://pub.dev/packages/liquid_glass_effect_flutter).
Its source repository is
[liquid_glass_effect_flutter](https://github.com/Keerthivasan-7/liquid_glass_effect_flutter);
the publication name and primary import are `liquid_glass_effect_flutter`.
Copy the package folder alongside your app, then add a path
dependency using its actual folder name:

```yaml
dependencies:
  flutter:
    sdk: flutter
  liquid_glass_effect_flutter:
    path: ../Liquid Glass
```

Run `flutter pub get` in your app. The package declares its own shader assets;
you do not need to copy them into your app's asset list.

## Joined controls in the development checkout

Put a `LiquidGlassCluster` on the glass plane of a `LiquidGlassScene`.
Each member supplies a stable ID, bounds in the cluster's logical coordinates,
and an ordinary Flutter foreground widget. Changing those bounds during an
animation moves the optics and the action together.

```dart
SizedBox(
  width: 240,
  height: 96,
  child: LiquidGlassCluster(
    blendRadius: 36,
    members: [
      LiquidGlassMember(
        id: 'minus',
        bounds: const Rect.fromLTWH(42, 20, 68, 56),
        child: IconButton(
          tooltip: 'Zoom out', onPressed: zoomOut, icon: const Icon(Icons.remove),
        ),
      ),
      LiquidGlassMember(
        id: 'plus',
        bounds: const Rect.fromLTWH(118, 20, 68, 56),
        child: IconButton(
          tooltip: 'Zoom in', onPressed: zoomIn, icon: const Icon(Icons.add),
        ),
      ),
    ],
  ),
)
```

Use the same material for every member of a cluster. The capture renderer
combines up to four axis-aligned capsules in list order. The whole cluster
can be positioned as one widget. Its padded paint box includes the bridge
and optical sampling reach. Leave space around controls inside the parent.
For more than four members, an explicit filter renderer, or a fallback
treatment, the controls use independent silhouettes. Reduced transparency
and high contrast choose the opaque treatment. Each action keeps its own
foreground hit area. The optical bridge adds no action.

`LiquidGlassLightingController.updateFromTilt` accepts pitch and roll in
radians. Use `updateFromPointer` for local pointer coordinates and the size
of the tracked area. A level pose or centered pointer gives front lighting.
The two most recent pointer-down impulses can overlap even with a fixed
light. Reduced motion suppresses their animation.

The Studio contains working examples of `LiquidGlassCard`,
`LiquidGlassButton`, `LiquidGlassNavBar`, and
`LiquidGlassSegmentedControl<T>`. [Studio source](../example/lib/studio/studio_page.dart)

## A working two-plane screen

Use `LiquidGlassScene` so the changing background is captured separately from
the glass controls. The following screen can be used as `MaterialApp.home`:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

class GlassDemoPage extends StatelessWidget {
  const GlassDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassScene(
        content: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 140),
          itemCount: 30,
          itemBuilder: (context, index) => Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            color: Colors.primaries[index % Colors.primaries.length],
            child: Text('Background item ${index + 1}'),
          ),
        ),
        glass: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LiquidGlass(
                config: const LiquidGlassConfig.regular(),
                interactive: true,
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action selected')),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

The foreground's `Align` and small control leave the background scrollable
outside that control. Put the scene itself in bounded space, such as a Scaffold
body. Keep refractable content in `content` and glass surfaces in `glass`.
Glass in the foreground is deliberately excluded from its own captured image.
Normal child buttons keep their callbacks, keyboard actions and semantics.
`interactive` adds visual feedback; it does not turn the surface into a button.

## Choose a material

| Configuration | Intended starting point |
|---|---|
| `LiquidGlassConfig.regular()` | Balanced toolbar, navigation and small controls |
| `LiquidGlassConfig.clear()` | More visible background and stronger lensing |
| `LiquidGlassConfig.frosted()` | More scattered backdrop beneath labels |
| `LiquidGlassConfig.performance()` | Simpler transmission sampling for repeated surfaces |

Start with static highlights, which are the default. Change one optical setting
at a time with `copyWith`. Keep foreground text contrast under app control:
background transparency cannot guarantee readable text over arbitrary images.
The presets describe different appearances and sampling choices; they do not
establish a measured speed ranking on your hardware.

## Apply comfort settings consistently

Pass the same policy to every surface belonging to one screen:

```dart
LiquidGlass(
  accessibility: const LiquidGlassAccessibilityPolicy(
    reduceTransparency: true,
    reduceMotion: true,
    // highContrast: null follows MediaQuery (the default).
  ),
  child: const Padding(
    padding: EdgeInsets.all(20),
    child: Text('Comfortable controls'),
  ),
)
```

Reduced transparency or high contrast selects an opaque surface without glass
capture, a shader or backdrop blur for that surface. The default opaque color
comes from the theme; `opaqueColor` overrides it. Explicit child text/icon
colors remain your app's responsibility. Expose reduced transparency as an
app setting when the platform does not provide a usable signal. Reduced motion
also follows `MediaQuery.disableAnimations` and `accessibleNavigation`.
Stop your app's own decorative animations separately, as the showcase does.

For large text, let the content grow and provide scrolling rather than a fixed
height that clips controls. Material buttons can supply explicit foreground
colors, so set those to match the opaque reading surface as well. Set
`VisualDensity.standard` when a button must retain a 48-pixel minimum: desktop
adaptive density can reduce that nominal minimum to 40 pixels. Verify final
bounds on the intended platforms. The shared
photographic accessibility fixture in `test/support/photo_accessibility_suite.dart`
demonstrates this at 320 logical pixels and up to 3× text scaling; its native
entry point and capture instructions are in the example README. A fixture pass
does not establish contrast for arbitrary translucent content.

## Scope and cost

Share a scene among related surfaces. The capture is the rectangular union of
their sampling bounds, so widely separated surfaces can still create a large
capture. Use small practical bounds and keep static overlays separate from
changing content. The scene's default capture `qualityScale` is 0.65; changing
it trades texture resolution against cost and should be reviewed on the target
device. Avoid a full-screen glass layer when only a small toolbar needs it.

Use `onRenderPathChanged` to observe the actual path. In a usable scene, `auto`
chooses scoped capture. Outside a scope it can choose the Impeller-only filter
or blur/tint fallback. Accessibility can intentionally select opaque fallback.
An observed capture failure downgrades the affected scope; the callback is a
diagnostic, not evidence that every backend has been qualified.

`onDiagnosticsChanged` on the scene reports capture dimensions, generations and
estimated image bytes. Send it to a small observer rather than rebuilding the
entire scene for every notification. Byte estimates do not measure GPU memory.

## Current delivery limits

The published renderer has current visual qualification on the named Android
GLES, Windows and browser targets, plus three completed foreground endurance
runs. A full v6 phone matrix retains twelve unstable groups. Four focused v7
groups pass, with forty-two still unmeasured. The phone has been released.
Human product/accessibility review and background/resume investigation remain
open. No renderer speedup, complete performance matrix, physical iOS or Vulkan
qualification is claimed. Consult [compatibility](COMPATIBILITY.md),
[performance](PERFORMANCE.md) and [release readiness](RELEASE_CHECKLIST.md)
before selecting a production target.
