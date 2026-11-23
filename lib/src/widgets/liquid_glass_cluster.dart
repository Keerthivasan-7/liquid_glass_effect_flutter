import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../configuration/liquid_glass_accessibility.dart';
import '../configuration/liquid_glass_config.dart';
import '../geometry/capsule_field.dart';
import '../geometry/liquid_glass_shape.dart';
import 'liquid_glass.dart';

/// A capsule and its foreground in a [LiquidGlassCluster]'s local coordinates.
@immutable
class LiquidGlassMember {
  const LiquidGlassMember(
      {required this.id,
      required this.bounds,
      required this.child,
      this.rotation = 0});

  /// Stable across position changes. IDs must be unique within a cluster.
  final Object id;

  /// Layout bounds before rotation, in cluster coordinates.
  final Rect bounds;

  /// Clockwise angle in radians around the center of [bounds].
  final double rotation;
  final Widget child;
}

/// Shades up to four independently oriented capsules as one surface inside a
/// [LiquidGlassScene]. List order determines smooth union and stacking order.
/// Give the cluster a bounded area. Leave room around members for the bridge.
/// Outside a capture scope, the same controls retain independent silhouettes.
/// Larger collections use separate glass surfaces for every member.
class LiquidGlassCluster extends StatelessWidget {
  const LiquidGlassCluster({
    required this.members,
    this.blendRadius = 32,
    this.config = const LiquidGlassConfig.clear(),
    this.accessibility = const LiquidGlassAccessibilityPolicy(),
    this.lightingController,
    this.onRenderPathChanged,
    super.key,
  }) : assert(blendRadius >= 0 && blendRadius < double.infinity);

  final List<LiquidGlassMember> members;
  final double blendRadius;
  final LiquidGlassConfig config;
  final LiquidGlassAccessibilityPolicy accessibility;
  final ValueListenable<Offset>? lightingController;
  final ValueChanged<LiquidGlassRenderPath>? onRenderPathChanged;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.expand();
    final ids = <Object>{};
    for (final member in members) {
      if (!member.bounds.isFinite ||
          member.bounds.isEmpty ||
          !member.rotation.isFinite ||
          !ids.add(member.id)) {
        throw ArgumentError(
            'Each glass member needs unique identity, finite rotation and finite, positive bounds.');
      }
    }
    if (members.length > 4 || config.renderer == LiquidGlassRenderer.shader) {
      return Stack(fit: StackFit.expand, children: [
        for (final member in members)
          Positioned.fromRect(
              key: ValueKey(member.id),
              rect: member.bounds,
              child: Transform.rotate(
                  angle: member.rotation,
                  child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(member.bounds.shortestSide / 2),
                      child: LiquidGlass(
                          shape: const LiquidGlassShape.capsule(),
                          config: _independentConfig(member),
                          accessibility: accessibility,
                          lightingController: lightingController,
                          onRenderPathChanged: onRenderPathChanged,
                          interactive: true,
                          child: member.child)))),
      ]);
    }
    final capsules = [
      for (final member in members)
        PlacedCapsule(member.bounds, member.rotation)
    ];
    final extents =
        capsules.map((c) => c.extent).reduce((a, b) => a.expandToInclude(b));
    // Each pairwise smooth-min can extend the field by at most k/4.
    final paintBox =
        extents.inflate(blendRadius * (members.length - 1) / 4 + 1);
    final local = [
      for (final capsule in capsules) capsule.shift(-paintBox.topLeft)
    ];
    return Stack(fit: StackFit.expand, children: [
      Positioned.fromRect(
          rect: paintBox,
          child: LiquidGlass(
            shape: CapsuleField(local, blendRadius),
            config: config,
            interactive: true,
            accessibility: accessibility,
            lightingController: lightingController,
            onRenderPathChanged: onRenderPathChanged,
            child: Stack(children: [
              for (var i = 0; i < members.length; i++)
                Positioned.fromRect(
                    key: ValueKey(members[i].id),
                    rect: local[i].bounds,
                    child: Transform.rotate(
                        angle: local[i].rotation,
                        child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(local[i].radius),
                            child: members[i].child))),
            ]),
          )),
    ]);
  }

  LiquidGlassConfig _independentConfig(LiquidGlassMember member) {
    // The filter binds a screen origin and uniform scale. Only the capture
    // path maps a rotated local basis into the actual source texture.
    if (member.rotation == 0) return config;
    return switch (config.renderer) {
      LiquidGlassRenderer.auto =>
        config.copyWith(renderer: LiquidGlassRenderer.capture),
      LiquidGlassRenderer.shader =>
        config.copyWith(renderer: LiquidGlassRenderer.fallback),
      _ => config,
    };
  }
}
