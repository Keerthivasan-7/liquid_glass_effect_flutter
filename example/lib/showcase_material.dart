import 'package:flutter/material.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

enum ShowcaseMaterial {
  regular('Regular', 'A soft, balanced surface for everyday controls.',
      Icons.layers_rounded),
  clear('Clear', 'More of the scene, with bright edges and deeper lensing.',
      Icons.water_drop_rounded),
  frosted('Frosted', 'A quieter backdrop for text and longer labels.',
      Icons.blur_on_rounded),
  lightweight('Lightweight', 'Subtle lensing with a sharper, simpler finish.',
      Icons.bolt_rounded);

  const ShowcaseMaterial(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  LiquidGlassConfig get configuration => switch (this) {
        regular => const LiquidGlassConfig.regular(),
        clear => const LiquidGlassConfig.clear(),
        frosted => const LiquidGlassConfig.frosted(),
        lightweight => const LiquidGlassConfig.performance(),
      };
}
