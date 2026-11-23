// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

/// A complete example of controller-free glass layout animation.
class AnimatedClusterDemo extends StatefulWidget {
  const AnimatedClusterDemo({super.key});
  @override
  State<AnimatedClusterDemo> createState() => _AnimatedClusterDemoState();
}

class _AnimatedClusterDemoState extends State<AnimatedClusterDemo> {
  bool _open = false;
  bool _saved = false;
  bool _quiet = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Morphing controls')),
        body: Column(children: [
          SwitchListTile(
              title: const Text('Reduce motion'),
              value: _quiet,
              onChanged: (value) => setState(() => _quiet = value)),
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                  'Tap the center control. Tap again during motion to reverse it.')),
          Expanded(
              child: LiquidGlassScene(
            content: const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                  Color(0xffb7ded3),
                  Color(0xff7599ce),
                  Color(0xffdfb7be)
                ]))),
            glass: LayoutBuilder(builder: (context, constraints) {
              final center = constraints.maxWidth / 2;
              final spread = (constraints.maxWidth / 2 - 42).clamp(56.0, 112.0);
              final y = constraints.maxHeight / 2;
              return AnimatedLiquidGlassCluster(
                duration: const Duration(milliseconds: 520),
                blendRadius: _open ? 24 : 40,
                accessibility:
                    LiquidGlassAccessibilityPolicy(reduceMotion: _quiet),
                members: [
                  LiquidGlassMember(
                      id: 'save',
                      bounds: Rect.fromCenter(
                          center: Offset(center - (_open ? spread : 52),
                              y - (_open ? 42 : 0)),
                          width: 48,
                          height: 48),
                      borderRadius: _open ? 14 : 24,
                      rotation: _open ? -.16 : 0,
                      child: IconButton(
                          tooltip: _saved ? 'Unsave' : 'Save',
                          onPressed: () => setState(() => _saved = !_saved),
                          icon: Icon(_saved
                              ? Icons.bookmark
                              : Icons.bookmark_outline))),
                  LiquidGlassMember(
                      id: 'toggle',
                      bounds: Rect.fromCenter(
                          center: Offset(center, y),
                          width: _open ? 92 : 56,
                          height: 56),
                      borderRadius: _open ? 18 : 28,
                      child: IconButton(
                          tooltip: _open ? 'Close controls' : 'Open controls',
                          onPressed: () => setState(() => _open = !_open),
                          icon: Icon(_open ? Icons.close : Icons.tune))),
                  LiquidGlassMember(
                      id: 'reset',
                      bounds: Rect.fromCenter(
                          center: Offset(center + (_open ? spread : 52),
                              y + (_open ? 42 : 0)),
                          width: 48,
                          height: 48),
                      borderRadius: _open ? 14 : 24,
                      rotation: _open ? .16 : 0,
                      child: IconButton(
                          tooltip: 'Reset',
                          onPressed: () => setState(() {
                                _saved = false;
                                _open = false;
                              }),
                          icon: const Icon(Icons.restart_alt))),
                ],
              );
            }),
          )),
        ]),
      );
}
