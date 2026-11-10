import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

enum StudioBackdrop { orbit, paper, charcoal, spectrum, atlas }

enum _Finish {
  clear('Clear', Icons.water_drop_outlined),
  satin('Satin', Icons.blur_on),
  prism('Prism', Icons.change_history);

  const _Finish(this.label, this.icon);
  final String label;
  final IconData icon;
  LiquidGlassConfig get material => switch (this) {
        _Finish.clear => const LiquidGlassConfig.clear(),
        _Finish.satin => const LiquidGlassConfig.frosted(),
        _Finish.prism => const LiquidGlassConfig.crystal().copyWith(
            dispersionStrength: 1.6,
            abbeNumber: 18,
            chromaticAberration: .004,
            vibrancy: .65,
            thinFilmStrength: .27,
            thinFilmThickness: 410),
      };
}

/// Interactive material review under fixed, reproducible viewing conditions.
class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage>
    with SingleTickerProviderStateMixin {
  final _light = LiquidGlassLightingController();
  final _path = ValueNotifier<LiquidGlassRenderPath?>(null);
  late final _join = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750), value: 1);
  _Finish _finish = _Finish.clear;
  StudioBackdrop _backdrop = StudioBackdrop.orbit;
  bool _followLight = false;
  bool _still = false;
  bool _joined = true;
  double _zoom = 1;
  bool _largeType = false;

  bool get _quiet =>
      _still ||
      MediaQuery.of(context).disableAnimations ||
      MediaQuery.of(context).accessibleNavigation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_quiet && _join.isAnimating) _join.value = _joined ? 1 : 0;
  }

  @override
  void dispose() {
    _join.dispose();
    _path.dispose();
    _light.dispose();
    super.dispose();
  }

  void _move(bool joined, {bool replay = false}) {
    setState(() => _joined = joined);
    final target = joined ? 1.0 : 0.0;
    if (_quiet) {
      _join.value = target;
    } else {
      if (replay) _join.value = 0;
      _join.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  void _reset() {
    _light.value = const Offset(-.65, -.75);
    _join.value = 1;
    setState(() {
      _finish = _Finish.clear;
      _backdrop = StudioBackdrop.orbit;
      _still = _followLight = _largeType = false;
      _joined = true;
      _zoom = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff355f55),
            surface: const Color(0xfff5f5ef)));
    final media = MediaQuery.of(context);
    return Theme(
        data: theme,
        child: MediaQuery(
          data: _largeType && media.textScaler.scale(16) < 32
              ? media.copyWith(textScaler: const TextScaler.linear(2))
              : media,
          child: Builder(builder: (context) => _buildStudio(context, theme)),
        ));
  }

  Widget _buildStudio(BuildContext context, ThemeData theme) {
    final policy = LiquidGlassAccessibilityPolicy(reduceMotion: _quiet);
    return Scaffold(
      backgroundColor: const Color(0xfff5f5ef),
      appBar: AppBar(
          backgroundColor: const Color(0xfff5f5ef),
          title: const Text('Optics Studio',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1)),
          actions: [
            TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/gallery'),
                icon: const Icon(Icons.layers_outlined),
                label: const Text('Gallery')),
            const SizedBox(width: 8),
          ]),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final stage = _stage(context, policy, wide ? 504 : 400);
              final controls = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Material',
                              style: theme.textTheme.titleLarge)),
                      IconButton(
                          onPressed: _reset,
                          tooltip: 'Reset studio',
                          icon: const Icon(Icons.restart_alt)),
                    ]),
                    LiquidGlassNavBar(
                        currentIndex: _finish.index,
                        padding: const EdgeInsets.all(4),
                        accessibility: policy,
                        items: [
                          for (final look in _Finish.values)
                            LiquidGlassNavItem(
                                icon: Icon(look.icon), label: look.label)
                        ],
                        onTap: (i) =>
                            setState(() => _finish = _Finish.values[i])),
                    const Divider(height: 32),
                    Text('Backdrop', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final b in StudioBackdrop.values)
                        ChoiceChip(
                            label: Text(_labels[b]!),
                            selected: b == _backdrop,
                            onSelected: (_) => setState(() => _backdrop = b)),
                    ]),
                    const SizedBox(height: 12),
                    Text('Illumination', style: theme.textTheme.titleMedium),
                    LiquidGlassSegmentedControl<bool>(
                        selected: _followLight,
                        accessibility: policy,
                        segments: const [
                          ButtonSegment(value: false, label: Text('Fixed')),
                          ButtonSegment(value: true, label: Text('Pointer')),
                        ],
                        onSelected: _quiet
                            ? null
                            : (v) => setState(() {
                                  _followLight = v;
                                  if (!v) {
                                    _light.value = const Offset(-.65, -.75);
                                  }
                                })),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Still motion'),
                        value: _quiet,
                        onChanged: MediaQuery.of(context).disableAnimations ||
                                MediaQuery.of(context).accessibleNavigation
                            ? null
                            : (v) => setState(() {
                                  _still = v;
                                  if (v) _join.value = _joined ? 1 : 0;
                                })),
                    Row(children: [
                      const Text('Spacing'),
                      Expanded(
                          child: AnimatedBuilder(
                              animation: _join,
                              builder: (context, _) => Slider(
                                  value: 1 - _join.value,
                                  semanticFormatterCallback: (v) =>
                                      '${(v * 100).round()} percent separated',
                                  onChanged: (v) => setState(() {
                                        _join.value = 1 - v;
                                        _joined = v < .5;
                                      }))))
                    ]),
                    OutlinedButton.icon(
                        onPressed: () => _move(true, replay: true),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Replay join')),
                    ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Render details'),
                        children: [
                          ValueListenableBuilder(
                              valueListenable: _path,
                              builder: (context, path, _) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      path == LiquidGlassRenderPath.capture
                                          ? 'Shared capsule field'
                                          : 'Independent capsules'),
                                  subtitle: Text(
                                      'Renderer · ${path?.name ?? 'loading'}'))),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Preview large text'),
                              value: _largeType,
                              onChanged: (v) => setState(() => _largeType = v))
                        ]),
                  ]);
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(flex: 7, child: stage),
                          const SizedBox(width: 28),
                          Expanded(flex: 3, child: controls),
                        ])
                  : Column(
                      children: [stage, const SizedBox(height: 16), controls]);
            }),
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Published showcase'),
                subtitle: const Text('Frozen reference · 0.1.0-dev.1'),
                children: [
                  Image.asset('assets/published-materials.png',
                      height: 300,
                      fit: BoxFit.contain,
                      semanticLabel:
                          'Materials gallery from the published prerelease')
                ]),
          ]),
        )),
      )),
    );
  }

  static const _labels = {
    StudioBackdrop.orbit: 'Orbit',
    StudioBackdrop.paper: 'Paper',
    StudioBackdrop.charcoal: 'Charcoal',
    StudioBackdrop.spectrum: 'Spectrum',
    StudioBackdrop.atlas: 'Atlas',
  };

  Widget _lenses(double width, LiquidGlassConfig material,
      LiquidGlassAccessibilityPolicy policy) {
    final scale = width >= 430 ? 1.25 : 1.0;
    final spread = math.min(104 * scale, (width - 54 * scale) / 2);
    const icons = [Icons.remove, Icons.center_focus_strong, Icons.add];
    const labels = ['Zoom out', 'Reset zoom', 'Zoom in'];
    return SizedBox(
        height: 120,
        child: AnimatedBuilder(
            animation: _join,
            builder: (context, _) {
              final spacing = spread + (64 * scale - spread) * _join.value;
              return LiquidGlassCluster(
                config: material,
                accessibility: policy,
                lightingController: _light,
                blendRadius: 32 * scale,
                onRenderPathChanged: (p) => _path.value = p,
                members: [
                  for (var i = 0; i < icons.length; i++)
                    LiquidGlassMember(
                        id: i,
                        bounds: Rect.fromCenter(
                            center: Offset(width / 2 + (i - 1) * spacing, 60),
                            width: (i == 1 ? 62 : 48) * scale,
                            height: 48 * scale),
                        child: IconButton(
                            tooltip: labels[i],
                            icon: Icon(icons[i], size: 22 * scale),
                            onPressed: () => setState(() {
                                  final delta = i == 0 ? -.18 : .18;
                                  _zoom = i == 1
                                      ? 1
                                      : (_zoom + delta).clamp(.65, 1.9);
                                }))),
                ],
              );
            }));
  }

  Widget _stage(BuildContext context, LiquidGlassAccessibilityPolicy policy,
      double baseHeight) {
    final dark = _backdrop != StudioBackdrop.paper;
    final ink = dark ? Colors.white : const Color(0xff182019);
    final large = MediaQuery.textScalerOf(context).scale(16) / 16;
    final height = baseHeight + math.max(0.0, large - 1) * 110;
    final material = _finish.material;
    final stageTheme = ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        useMaterial3: true);
    return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(builder: (context, constraints) {
            void follow(Offset position) {
              if (_followLight && !_quiet) {
                _light.updateFromPointer(position, constraints.biggest);
              }
            }

            return MouseRegion(
                onHover: (e) => follow(e.localPosition),
                child: Listener(
                  onPointerMove: (e) => follow(e.localPosition),
                  child: Theme(
                      data: stageTheme,
                      child: DefaultTextStyle(
                        style: TextStyle(color: ink),
                        child: LiquidGlassScene(
                          qualityScale: 1,
                          content: _StudioBackground(
                              backdrop: _backdrop, zoom: _zoom),
                          glass: Stack(children: [
                            Positioned(
                                left: 18,
                                top: 18,
                                right: 18,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: LiquidGlassCard(
                                        config: material,
                                        lightingController: _light,
                                        accessibility: policy,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (_backdrop ==
                                                      StudioBackdrop.orbit ||
                                                  _backdrop ==
                                                      StudioBackdrop.atlas)
                                                const Text('NASA  /  2002',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 1.4)),
                                              Text(
                                                  _backdrop ==
                                                              StudioBackdrop
                                                                  .orbit ||
                                                          _backdrop ==
                                                              StudioBackdrop
                                                                  .atlas
                                                      ? 'Blue Marble'
                                                      : _labels[_backdrop]!,
                                                  style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: -1.2)),
                                            ])))),
                            Align(
                                alignment: Alignment.center,
                                child: _lenses(
                                    constraints.maxWidth, material, policy)),
                            Positioned(
                                left: 18,
                                right: 18,
                                bottom: 20,
                                child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: LiquidGlassButton(
                                        config: material,
                                        accessibility: policy,
                                        lightingController: _light,
                                        onPressed: () => _move(!_joined),
                                        child: Wrap(
                                            spacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Icon(
                                                  _joined
                                                      ? Icons.unfold_more
                                                      : Icons.unfold_less,
                                                  size: 17),
                                              Text(_joined
                                                  ? 'Separate lenses'
                                                  : 'Join lenses')
                                            ])))),
                          ]),
                        ),
                      )),
                ));
          }),
        ));
  }
}

class _StudioBackground extends StatelessWidget {
  const _StudioBackground({required this.backdrop, required this.zoom});
  final StudioBackdrop backdrop;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final photo =
        backdrop == StudioBackdrop.orbit || backdrop == StudioBackdrop.atlas;
    return ColoredBox(
        color: backdrop == StudioBackdrop.paper
            ? const Color(0xffeeeee6)
            : const Color(0xff111a22),
        child: ClipRect(
            child: Stack(fit: StackFit.expand, children: [
          if (photo)
            Transform.scale(
                scale: zoom * 1.45,
                alignment: const Alignment(.15, .1),
                child: Image.asset('assets/blue_marble_2002.jpg',
                    fit: BoxFit.cover, excludeFromSemantics: true)),
          if (photo)
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                  Color(0x9906131c),
                  Color(0x33111d23),
                  Color(0xa6111d23)
                ]))),
          if (!photo || backdrop == StudioBackdrop.atlas)
            CustomPaint(painter: _MapLines(backdrop, zoom)),
          if (backdrop == StudioBackdrop.atlas)
            const Positioned(
                right: 18,
                bottom: 98,
                child: ExcludeSemantics(
                    child: Text('PACIFIC\nOCEAN',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 4,
                            height: 1.5)))),
        ])));
  }
}

class _MapLines extends CustomPainter {
  const _MapLines(this.backdrop, this.zoom);
  final StudioBackdrop backdrop;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    if (backdrop == StudioBackdrop.spectrum) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff304856),
                Color(0xff12696b),
                Color(0xff435189),
                Color(0xff9e3764)
              ],
            ).createShader(Offset.zero & size));
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color =
          backdrop == StudioBackdrop.paper ? Colors.black26 : Colors.white30;
    final center = Offset(size.width * .89, size.height * .84);
    for (var i = 1; i <= 30; i++) {
      final radius = i * size.longestSide / 22 * zoom;
      canvas.drawOval(
          Rect.fromCenter(
              center: center, width: radius * 2.1, height: radius * 1.5),
          paint);
    }
  }

  @override
  bool shouldRepaint(_MapLines old) =>
      backdrop != old.backdrop || zoom != old.zoom;
}
