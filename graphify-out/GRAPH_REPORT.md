# Graph Report - lib  (2026-11-10)

## Corpus Check
- 13 files · ~8,529 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 419 nodes · 479 edges · 21 communities (16 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `24c3080c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- liquid_glass.dart
- liquid_glass_scope.dart
- liquid_glass_config.dart
- liquid_glass_group.dart
- capture_footprint.dart
- liquid_glass_accessibility.dart
- liquid_glass_scene.dart
- shader_manager.dart
- _LiquidGlassGroupState
- @meta
- liquid_glass_effect_flutter.dart
- _RenderLiquidGlassScope
- _LiquidGlassClipper
- CustomPainter
- _CaptureGlassLayer
- liquid_glass_effect_flutter.dart
- _LiquidGlassScopeRenderWidget
- SingleChildRenderObjectWidget
- _FilterGlassLayer
- _CaptureBackgroundLayer
- InheritedWidget

## God Nodes (most connected - your core abstractions)
1. `_LiquidGlassState` - 4 edges
2. `LiquidGlassMotionHandle` - 4 edges
3. `_LiquidGlassGroupState` - 4 edges
4. `LiquidGlassCaptureHandle` - 4 edges
5. `_RenderLiquidGlassScope` - 4 edges
6. `LiquidGlassAccessibilityPolicy` - 3 edges
7. `LiquidGlassConfig` - 3 edges
8. `LiquidGlassShape` - 3 edges
9. `LiquidGlass` - 3 edges
10. `_RenderCaptureGlassSurface` - 3 edges

## Surprising Connections (you probably didn't know these)
- `_RenderCaptureGlassSurface` --implements--> `LiquidGlassCaptureClient`  [EXTRACTED]
  lib/src/widgets/liquid_glass.dart → lib/src/widgets/liquid_glass_scope.dart

## Import Cycles
- None detected.

## Communities (21 total, 5 thin omitted)

### Community 0 - "liquid_glass.dart"
Cohesion: 0.02
Nodes (106): AnimationController, class _RenderCaptureGlassSurface extends, Color get, ../configuration/liquid_glass_accessibility.dart, Duration get, EdgeInsetsGeometry, FragmentShader?, ../geometry/liquid_glass_shape.dart (+98 more)

### Community 1 - "liquid_glass_scope.dart"
Cohesion: 0.03
Nodes (75): class _RenderLiquidGlassScope extends RenderBox, Image?, Image? get, List, package:flutter/rendering.dart, Rect, Rect get, RenderBox? get (+67 more)

### Community 2 - "liquid_glass_config.dart"
Cohesion: 0.04
Nodes (52): abbeNumber, absorptionColor, absorptionStrength, animateLight, animationDuration, anisotropy, anisotropyRotation, blurSigma (+44 more)

### Community 3 - "liquid_glass_group.dart"
Cohesion: 0.05
Nodes (39): bool get, Duration, int?, LiquidGlassMotion get, Offset, package:flutter/scheduler.dart, package:meta/meta.dart, active (+31 more)

### Community 4 - "capture_footprint.dart"
Cohesion: 0.05
Nodes (37): @immutable, ../configuration/liquid_glass_config.dart, dart:math, double get, package:flutter/material.dart, LiquidGlassAccessibilityPolicy, LiquidGlassConfig, borderRadius (+29 more)

### Community 5 - "liquid_glass_accessibility.dart"
Cohesion: 0.11
Nodes (16): bool?, Color, dart:ui, int get, package:flutter/foundation.dart, hashCode, highContrast, opaqueColor (+8 more)

### Community 6 - "liquid_glass_scene.dart"
Cohesion: 0.14
Nodes (13): double?, liquid_glass_scope.dart, package:flutter/widgets.dart, build, content, glass, LiquidGlassScene, onDiagnosticsChanged (+5 more)

### Community 7 - "shader_manager.dart"
Cohesion: 0.14
Nodes (13): FragmentProgram?, captureAssetKey, _captureLoad, _captureProgram, filterAssetKey, _filterLoad, _filterProgram, LiquidGlassShaderManager (+5 more)

### Community 8 - "_LiquidGlassGroupState"
Cohesion: 0.24
Nodes (10): SingleTickerProviderStateMixin, LiquidGlassGroup, _LiquidGlassGroupState, LiquidGlass, _LiquidGlassState, LiquidGlassScope, _LiquidGlassScopeState, State (+2 more)

### Community 9 - "@meta"
Cohesion: 0.22
Nodes (10): @meta, ChangeNotifier, LiquidGlassMotionHandle, liquidGlassMotionOf, _RenderCaptureGlassSurface, _RenderFilterGlassBackdrop, RenderProxyBox, LiquidGlassCaptureClient (+2 more)

### Community 10 - "liquid_glass_effect_flutter.dart"
Cohesion: 0.22
Nodes (8): src/configuration/liquid_glass_accessibility.dart, src/configuration/liquid_glass_config.dart, src/geometry/liquid_glass_shape.dart, src/rendering/liquid_glass_capabilities.dart, src/widgets/liquid_glass.dart, src/widgets/liquid_glass_group.dart, src/widgets/liquid_glass_scene.dart, src/widgets/liquid_glass_scope.dart

### Community 11 - "_RenderLiquidGlassScope"
Cohesion: 0.33
Nodes (6): ContainerBoxParentData, ContainerRenderObjectMixin, RenderBox, RenderBoxContainerDefaultsMixin, _LiquidGlassScopeParentData, _RenderLiquidGlassScope

### Community 12 - "_LiquidGlassClipper"
Cohesion: 0.67
Nodes (3): CustomClipper, Path, _LiquidGlassClipper

### Community 13 - "CustomPainter"
Cohesion: 0.67
Nodes (3): CustomPainter, _GlassFocusPainter, _GlassOverlayPainter

### Community 17 - "SingleChildRenderObjectWidget"
Cohesion: 0.67
Nodes (3): SingleChildRenderObjectWidget, _CaptureGlassSurface, _FilterGlassBackdrop

### Community 20 - "InheritedWidget"
Cohesion: 0.67
Nodes (3): InheritedWidget, _LiquidGlassMotionInherited, _LiquidGlassScopeInherited

## Knowledge Gaps
- **286 isolated node(s):** `reduceTransparency`, `reduceMotion`, `highContrast`, `opaqueColor`, `operator` (+281 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 342 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LiquidGlassConfig` connect `capture_footprint.dart` to `liquid_glass.dart`, `liquid_glass_config.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `LiquidGlassCaptureHandle` connect `@meta` to `liquid_glass.dart`, `liquid_glass_scope.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `LiquidGlassRenderPath` connect `liquid_glass_config.dart` to `liquid_glass.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `reduceTransparency`, `reduceMotion`, `highContrast` to the rest of the system?**
  _286 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `liquid_glass.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.018691588785046728 - nodes in this community are weakly interconnected._
- **Should `liquid_glass_scope.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02631578947368421 - nodes in this community are weakly interconnected._
- **Should `liquid_glass_config.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._