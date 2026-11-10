# Visual foundation audit and corrections

The supplied visual audit was checked against the uncommitted working tree on
10 November 2026. Existing lighting-controller, component and optical edits
were retained. This is a local source snapshot based on main `4d9fd31`, not a
new published version or a claim that earlier runtime qualification covers the
new shaders.

Two focused regressions failed before correction:

- A near-transparent black tint changed a sampled color channel by 29 levels.
  The soft-light response was applied with substantial strength immediately
  above the tint threshold instead of fading with opacity.
- The actual jittered displacement reached 90.6989 logical pixels in a legal
  configuration while the protected transmission reach was only 83.21.

Corrections apply to both shader paths where relevant: tint now approaches its
identity continuously, the studio softbox uses defined ascending `smoothstep`
edges, and the capture footprint includes the entire 1.09 jitter scale before
the scatter stencil. The footprint regression evaluates that emitted scale.

After correction, all 31 focused pixel/geometry/component/visual-contract checks
pass. The full package integration run passes 86 tests. Analysis reports no
issues. Logs, source hashes and their exact scope are recorded in
[source-and-results.json](source-and-results.json). The analysis run also covered
the unfinished lifecycle diagnostic before it was preserved separately; that
diagnostic is not included in the 86-test integration run or this visual source
snapshot.

The phone was not used. These widget-engine results do not approve the visual
design on physical devices, prove physical spectral/fluid simulation, close the
backgrounding issue, or establish superiority over Apple or another package.
The [visual implementation plan](../../../VISUAL_EXCELLENCE_PLAN.md) records the
next visible deliverables and the remaining model/interaction work.
