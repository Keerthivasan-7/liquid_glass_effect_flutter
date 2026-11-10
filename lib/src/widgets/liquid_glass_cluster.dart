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
      {required this.id, required this.bounds, required this.child});

  /// Stable across position changes. IDs must be unique within a cluster.
  final Object id;
  final Rect bounds;
  final Widget child;
}

/// Shades up to four axis-aligned capsules as a single glass surface inside a
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
          !ids.add(member.id)) {
        throw ArgumentError(
            'Each glass member needs unique identity and finite, positive bounds.');
      }
    }
    if (members.length > 4 || config.renderer == LiquidGlassRenderer.shader) {
      return Stack(fit: StackFit.expand, children: [
        for (final member in members)
          Positioned.fromRect(
              key: ValueKey(member.id),
              rect: member.bounds,
              child: LiquidGlass(
                  shape: const LiquidGlassShape.capsule(),
                  config: config,
                  accessibility: accessibility,
                  lightingController: lightingController,
                  onRenderPathChanged: onRenderPathChanged,
                  interactive: true,
                  child: member.child)),
      ]);
    }
    final extents =
        members.map((m) => m.bounds).reduce((a, b) => a.expandToInclude(b));
    // Each pairwise smooth-min can extend the field by at most k/4.
    final paintBox =
        extents.inflate(blendRadius * (members.length - 1) / 4 + 1);
    final local = [
      for (final member in members) member.bounds.shift(-paintBox.topLeft)
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
                    rect: local[i],
                    child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(local[i].shortestSide / 2),
                        child: members[i].child)),
            ]),
          )),
    ]);
  }
}
