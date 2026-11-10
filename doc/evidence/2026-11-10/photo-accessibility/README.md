# Photographic opaque-reading accessibility fixture

On 10 November 2026, all **twelve Windows/profile cases** passed with twenty-four
native PNG exports. The same twelve cases pass in the widget test engine with
the Windows platform variant. The widget engine uses a placeholder font; the
native images contain actual text. The phone was not used.

The screen combines a credited NASA Earth Observatory satellite-data composite
with a 320 × 568 logical-pixel scrollable reading panel. Cases cover two surface
colors, explicit reduced transparency or inherited high contrast, and text
scales 1×, 2× and 3×. Assertions check opaque pixels, varied source-image pixels,
inherited foreground and explicit button ink, calculated contrast ≥ 4.5,
zero captures/retained images, reachable controls at least 48 × 48, keyboard
activation and exactly one action semantics label. The source and credit are
in [the example assets](../../../../example/assets/README.md).

- [Source identity, scope and results](source-and-results.json)
- [Exact SDK](sdk.json), resolved example lock and artifact hashes
- [Passing native export](windows-passed/runtime.json) and session log
- [Widget matrix log](widget-tests.log)
- [Rejected original native export](windows-failed-density/runtime.json)

The initial native run exposed a real fixture problem: adaptive desktop density
reduced a nominal 48-pixel minimum button to 40 pixels. Eight cases failed and
four completed; that run is rejected and retained. Setting the button's
`VisualDensity.standard` fixes its dimensions. The updated widget entry point
uses Flutter's supported Windows variant, so this desktop regression also runs
on hosted Linux checks. The host rejects a nonempty but incomplete named matrix.

The native session emits the SDK's Windows integration-plugin warning. Its
actual response was nevertheless received and preserved by the host: twelve
observations, twenty-four images, no assertion errors, and driver exit zero.
The source manifest verifies every relevant isolated-checkout file against the
committed fixture source. All production renderer files remain unchanged.

The assistant inspected four representative native exports: normal light mode,
the top and focused action at 3× in light mode, and the focused action at 3× in
dark mode. Text wraps and the action remains accessible by scrolling. This is
**not human product approval**. Other platforms, physical-device/screen-reader
usability, arbitrary product photographs and translucent text contrast remain
unverified for this fixture. It is independent of optical fixture v5 and does
not expand the renderer's verified backend matrix or establish performance.
