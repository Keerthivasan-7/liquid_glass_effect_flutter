# Graph Report - lib  (2026-11-10)

## Corpus Check
- 21 files · ~11,227 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 540 nodes · 677 edges · 27 communities (22 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4d9fd31e`
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
- _RenderCaptureGlassSurface
- liquid_glass_effect_flutter.dart
- _RenderLiquidGlassScope
- _LiquidGlassClipper
- glass_selection_track.dart
- _CaptureGlassLayer
- liquid_glass_effect_flutter.dart
- _LiquidGlassScopeRenderWidget
- SingleChildRenderObjectWidget
- _FilterGlassLayer
- _CaptureBackgroundLayer
- liquid_glass_nav_bar.dart
- liquid_glass_button.dart
- liquid_glass_card.dart
- liquid_glass_cluster.dart
- liquid_glass_segmented_control.dart
- @immutable
- StatelessWidget

## God Nodes (most connected - your core abstractions)
1. `LiquidGlassAccessibilityPolicy` - 8 edges
2. `LiquidGlassConfig` - 8 edges
3. `LiquidGlassShape` - 4 edges
4. `_LiquidGlassState` - 4 edges
5. `LiquidGlassMotionHandle` - 4 edges
6. `_LiquidGlassGroupState` - 4 edges
7. `LiquidGlassCaptureHandle` - 4 edges
8. `_RenderLiquidGlassScope` - 4 edges
9. `LiquidGlassLightingController` - 3 edges
10. `_StretchTween` - 3 edges

## Surprising Connections (you probably didn't know these)
- `CapsuleField` --inherits--> `LiquidGlassShape`  [EXTRACTED]
  lib/src/geometry/capsule_field.dart → lib/src/geometry/liquid_glass_shape.dart
- `_RenderCaptureGlassSurface` --implements--> `LiquidGlassCaptureClient`  [EXTRACTED]
  lib/src/widgets/liquid_glass.dart → lib/src/widgets/liquid_glass_scope.dart

## Import Cycles
- None detected.

## Communities (27 total, 5 thin omitted)

### Community 0 - "liquid_glass.dart"
Cohesion: 0.02
Nodes (112): AnimationController, class _RenderCaptureGlassSurface extends, Color get, Duration get, FragmentShader?, GlobalKey, liquid_glass_group.dart, Object? (+104 more)

### Community 1 - "liquid_glass_scope.dart"
Cohesion: 0.03
Nodes (73): class _RenderLiquidGlassScope extends RenderBox, Image?, Image? get, package:flutter/rendering.dart, Rect get, RenderBox? get, Set, Size (+65 more)

### Community 2 - "liquid_glass_config.dart"
Cohesion: 0.04
Nodes (53): abbeNumber, absorptionColor, absorptionStrength, animateLight, animationDuration, anisotropy, anisotropyRotation, blurSigma (+45 more)

### Community 3 - "liquid_glass_group.dart"
Cohesion: 0.04
Nodes (47): @meta, bool get, ChangeNotifier, Duration, InheritedWidget, int?, LiquidGlassMotion get, package:flutter/scheduler.dart (+39 more)

### Community 4 - "capture_footprint.dart"
Cohesion: 0.06
Nodes (34): dart:math, double get, Offset, package:flutter/material.dart, LiquidGlassLightingController, _unitDisk, updateFromPointer, updateFromTilt (+26 more)

### Community 5 - "liquid_glass_accessibility.dart"
Cohesion: 0.20
Nodes (9): bool?, int get, package:flutter/foundation.dart, hashCode, highContrast, opaqueColor, operator, reduceMotion (+1 more)

### Community 6 - "liquid_glass_scene.dart"
Cohesion: 0.17
Nodes (11): double?, liquid_glass_scope.dart, package:flutter/widgets.dart, build, content, glass, onDiagnosticsChanged, pixelRatio (+3 more)

### Community 7 - "shader_manager.dart"
Cohesion: 0.07
Nodes (27): dart:ui, FragmentProgram?, liquid_glass_shape.dart, List, blendRadius, CapsuleField, member, members (+19 more)

### Community 8 - "_LiquidGlassGroupState"
Cohesion: 0.24
Nodes (10): SingleTickerProviderStateMixin, LiquidGlassGroup, _LiquidGlassGroupState, LiquidGlass, _LiquidGlassState, LiquidGlassScope, _LiquidGlassScopeState, State (+2 more)

### Community 9 - "_RenderCaptureGlassSurface"
Cohesion: 0.50
Nodes (4): _RenderCaptureGlassSurface, _RenderFilterGlassBackdrop, RenderProxyBox, LiquidGlassCaptureClient

### Community 10 - "liquid_glass_effect_flutter.dart"
Cohesion: 0.13
Nodes (14): src/configuration/liquid_glass_accessibility.dart, src/configuration/liquid_glass_config.dart, src/configuration/liquid_glass_controller.dart, src/geometry/liquid_glass_shape.dart, src/rendering/liquid_glass_capabilities.dart, src/widgets/liquid_glass_button.dart, src/widgets/liquid_glass_card.dart, src/widgets/liquid_glass_cluster.dart (+6 more)

### Community 11 - "_RenderLiquidGlassScope"
Cohesion: 0.33
Nodes (6): ContainerBoxParentData, ContainerRenderObjectMixin, RenderBox, RenderBoxContainerDefaultsMixin, _LiquidGlassScopeParentData, _RenderLiquidGlassScope

### Community 12 - "_LiquidGlassClipper"
Cohesion: 0.67
Nodes (3): CustomClipper, Path, _LiquidGlassClipper

### Community 13 - "glass_selection_track.dart"
Cohesion: 0.11
Nodes (18): Color?, CustomPainter, Rect, bounds, build, children, color, index (+10 more)

### Community 17 - "SingleChildRenderObjectWidget"
Cohesion: 0.67
Nodes (3): SingleChildRenderObjectWidget, _CaptureGlassSurface, _FilterGlassBackdrop

### Community 20 - "liquid_glass_nav_bar.dart"
Cohesion: 0.11
Nodes (18): accessibility, activeIndicatorColor, borderRadius, build, config, currentIndex, height, icon (+10 more)

### Community 21 - "liquid_glass_button.dart"
Cohesion: 0.12
Nodes (15): package:flutter/services.dart, accessibility, borderRadius, build, child, config, cornerSmoothing, enableHaptics (+7 more)

### Community 22 - "liquid_glass_card.dart"
Cohesion: 0.13
Nodes (14): EdgeInsetsGeometry, ../geometry/liquid_glass_shape.dart, accessibility, borderRadius, build, child, config, cornerSmoothing (+6 more)

### Community 23 - "liquid_glass_cluster.dart"
Cohesion: 0.15
Nodes (12): ../geometry/capsule_field.dart, accessibility, blendRadius, bounds, build, child, config, id (+4 more)

### Community 24 - "liquid_glass_segmented_control.dart"
Cohesion: 0.17
Nodes (11): ../configuration/liquid_glass_accessibility.dart, ../configuration/liquid_glass_config.dart, glass_selection_track.dart, liquid_glass.dart, accessibility, build, config, onSelected (+3 more)

### Community 25 - "@immutable"
Cohesion: 0.25
Nodes (8): @immutable, LiquidGlassAccessibilityPolicy, LiquidGlassConfig, LiquidGlassCaptureFootprint, LiquidGlassMember, _GlassMotionSample, LiquidGlassMotion, LiquidGlassDiagnostics

### Community 26 - "StatelessWidget"
Cohesion: 0.25
Nodes (8): GlassSelectionTrack, LiquidGlassButton, LiquidGlassCard, LiquidGlassCluster, LiquidGlassNavBar, LiquidGlassScene, LiquidGlassSegmentedControl, StatelessWidget

## Knowledge Gaps
- **372 isolated node(s):** `reduceTransparency`, `reduceMotion`, `highContrast`, `opaqueColor`, `operator` (+367 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 432 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `LiquidGlassConfig` connect `@immutable` to `liquid_glass.dart`, `liquid_glass_config.dart`, `liquid_glass_nav_bar.dart`, `liquid_glass_button.dart`, `liquid_glass_card.dart`, `liquid_glass_cluster.dart`, `liquid_glass_segmented_control.dart`?**
  _High betweenness centrality (0.042) - this node is a cross-community bridge._
- **Why does `LiquidGlassAccessibilityPolicy` connect `@immutable` to `liquid_glass.dart`, `liquid_glass_accessibility.dart`, `liquid_glass_nav_bar.dart`, `liquid_glass_button.dart`, `liquid_glass_card.dart`, `liquid_glass_cluster.dart`, `liquid_glass_segmented_control.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `LiquidGlassCaptureHandle` connect `liquid_glass_group.dart` to `liquid_glass.dart`, `liquid_glass_scope.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `reduceTransparency`, `reduceMotion`, `highContrast` to the rest of the system?**
  _372 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `liquid_glass.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.017699115044247787 - nodes in this community are weakly interconnected._
- **Should `liquid_glass_scope.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Should `liquid_glass_config.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._