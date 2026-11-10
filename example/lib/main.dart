import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_optics_flutter/liquid_optics_flutter.dart';

import 'showcase_material.dart';

void main() => runApp(const ShowcaseApp());

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Liquid Glass',
        theme: ThemeData(useMaterial3: true),
        home: const ShowcasePage(),
      );
}

enum _Section { materials, controls, comfort }

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final _scroll = ScrollController();
  final _tuningKey = GlobalKey();
  final _diagnostics = ValueNotifier<LiquidGlassDiagnostics?>(null);
  final _saved = <ShowcaseMaterial>{};
  _Section _section = _Section.materials;
  ShowcaseMaterial _material = ShowcaseMaterial.regular;
  LiquidGlassConfig _config = const LiquidGlassConfig.regular();
  bool _customized = false;
  bool _dark = false;
  bool _showTuning = false;
  bool _reduceMotion = false;
  bool _reduceTransparency = false;
  bool _highContrast = false;

  Color get _ink => _dark ? const Color(0xFFF4F7FF) : const Color(0xFF142238);
  Color get _surface => _dark ? const Color(0xFF142033) : Colors.white;
  bool get _contrastOn => _highContrast || MediaQuery.of(context).highContrast;
  Color get _quiet => _ink.withValues(alpha: _contrastOn ? 1 : 0.68);
  bool get _motionOff =>
      _reduceMotion ||
      MediaQuery.of(context).disableAnimations ||
      MediaQuery.of(context).accessibleNavigation;
  LiquidGlassAccessibilityPolicy get _policy => LiquidGlassAccessibilityPolicy(
        reduceMotion: _reduceMotion,
        reduceTransparency: _reduceTransparency,
        highContrast: _highContrast ? true : null,
        opaqueColor: _surface,
      );

  @override
  void dispose() {
    _scroll.dispose();
    _diagnostics.dispose();
    super.dispose();
  }

  void _chooseMaterial(ShowcaseMaterial material) => setState(() {
        final animate = _config.animateLight;
        _material = material;
        _config = material.configuration.copyWith(animateLight: animate);
        _customized = false;
      });

  void _tune(LiquidGlassConfig config) => setState(() {
        _config = config;
        _customized = true;
      });

  void _chooseSection(_Section section) {
    if (_section == section) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _section = section);
  }

  void _openTuning() {
    final shouldOpen = _section != _Section.materials || !_showTuning;
    _chooseSection(_Section.materials);
    setState(() => _showTuning = shouldOpen);
    if (!_showTuning) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _tuningKey.currentContext;
      if (mounted && target != null) {
        Scrollable.ensureVisible(target,
            alignment: 0.08,
            duration:
                _motionOff ? Duration.zero : const Duration(milliseconds: 250));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF246BFD),
        brightness: _dark ? Brightness.dark : Brightness.light);
    final media = MediaQuery.of(context);
    return Theme(
      data: ThemeData(colorScheme: scheme, useMaterial3: true),
      child: MediaQuery(
        data: media.copyWith(
            disableAnimations: media.disableAnimations || _reduceMotion),
        child: Scaffold(
          body: LiquidGlassScene(
            qualityScale: 0.65,
            // Updating this small observer never rebuilds the backdrop or glass.
            onDiagnosticsChanged: (value) {
              if (mounted) _diagnostics.value = value;
            },
            content: AnimatedContainer(
              duration: _motionOff
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _dark
                      ? const [
                          Color(0xFF09121F),
                          Color(0xFF1B1531),
                          Color(0xFF07262C)
                        ]
                      : const [
                          Color(0xFFF0F6FF),
                          Color(0xFFE3F4FF),
                          Color(0xFFFFEDF2)
                        ],
                ),
              ),
              child: CustomPaint(
                  painter: _BackdropPainter(
                      dark: _dark, scroll: _scroll, reduceMotion: _motionOff)),
            ),
            glass: LiquidGlassGroup(
              influenceRadius: 220,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(children: [
                  _toolbar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(4, 24, 4, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: switch (_section) {
                            _Section.materials => _materialsPage(),
                            _Section.controls => _controlsPage(),
                            _Section.comfort => _comfortPage(),
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _navigation(),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glass(
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(20),
          LiquidGlassShape shape =
              const LiquidGlassShape.roundedRectangle()}) =>
      LiquidGlass(
        config: _config,
        accessibility: _policy,
        interactive: true,
        shape: shape,
        padding: padding,
        child: Material(type: MaterialType.transparency, child: child),
      );

  Widget _toolbar() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _glass(
          shape: const LiquidGlassShape.capsule(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(children: [
            Expanded(
              child: PopupMenuButton<ShowcaseMaterial>(
                tooltip: 'Choose a glass material',
                popUpAnimationStyle:
                    _motionOff ? AnimationStyle.noAnimation : null,
                onSelected: _chooseMaterial,
                itemBuilder: (context) => [
                  for (final material in ShowcaseMaterial.values)
                    PopupMenuItem(
                      value: material,
                      child: Row(children: [
                        Icon(material.icon, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(material.label)),
                        if (_material == material)
                          const Icon(Icons.check_rounded, size: 18),
                      ]),
                    ),
                ],
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Row(children: [
                    Icon(_material.icon, color: _ink, size: 22),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(
                            '${_material.label}${_customized ? ' · Custom' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _ink, fontWeight: FontWeight.w700))),
                    Icon(Icons.expand_more_rounded, color: _ink, size: 19),
                  ]),
                ),
              ),
            ),
            IconButton(
              tooltip: _dark ? 'Use light appearance' : 'Use dark appearance',
              onPressed: () => setState(() => _dark = !_dark),
              icon: Icon(
                  _dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: _ink),
            ),
            IconButton(
                tooltip: 'Adjust material',
                onPressed: _openTuning,
                icon: Icon(Icons.tune_rounded, color: _ink)),
          ]),
        ),
      );

  Widget _heading(String eyebrow, String title, String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: TextStyle(
                  color: _quiet,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: _ink,
                  fontSize: MediaQuery.of(context).size.width < 500 ? 38 : 54,
                  height: 1.04,
                  letterSpacing: -1.8,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(description,
              style: TextStyle(color: _quiet, fontSize: 16, height: 1.5)),
          const SizedBox(height: 28),
        ],
      );

  Widget _materialsPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading(
              'LIQUID GLASS / FLUTTER',
              'A little depth.\nA different feeling.',
              'Choose a finish, then scroll. The floating controls bend the moving backdrop while their labels stay sharp.'),
          _glass(
              child: Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFF246BFD).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(_material.icon, color: _ink)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_material.label,
                      style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                      _customized
                          ? 'Your custom finish'
                          : _material.description,
                      style: TextStyle(color: _quiet, height: 1.35)),
                ])),
            IconButton(
              tooltip: _saved.contains(_material)
                  ? 'Unsave this material'
                  : 'Save this material',
              onPressed: () => setState(() {
                if (!_saved.add(_material)) _saved.remove(_material);
              }),
              icon: Icon(
                  _saved.contains(_material)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: _ink),
            ),
          ])),
          const SizedBox(height: 26),
          Text('Find your finish',
              style: TextStyle(
                  color: _ink, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 580 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final material in ShowcaseMaterial.values)
                SizedBox(width: width, child: _presetCard(material)),
            ]);
          }),
          const SizedBox(height: 20),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: _openTuning,
                  icon: Icon(_showTuning
                      ? Icons.expand_less_rounded
                      : Icons.tune_rounded),
                  label: Text(_showTuning
                      ? 'Hide fine adjustments'
                      : 'Fine adjustments'))),
          if (_showTuning) _tuningPanel(),
          const SizedBox(height: 14),
          Text('Saved finishes stay available while this preview is open.',
              style: TextStyle(color: _quiet, fontSize: 12)),
        ],
      );

  Widget _presetCard(ShowcaseMaterial material) {
    final selected = material == _material;
    return Semantics(
      selected: selected,
      child: Material(
        color: _surface.withValues(alpha: _contrastOn ? 1 : 0.82),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
                color: selected
                    ? const Color(0xFF246BFD)
                    : _ink.withValues(alpha: 0.06),
                width: selected ? 2 : 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _chooseMaterial(material),
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(material.icon, color: _ink),
                    const Spacer(),
                    if (_saved.contains(material))
                      Icon(Icons.bookmark_rounded, size: 17, color: _quiet),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF246BFD))
                  ]),
                  const SizedBox(height: 16),
                  Text(material.label,
                      style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(material.description,
                      style: TextStyle(color: _quiet, height: 1.4)),
                ],
              )),
        ),
      ),
    );
  }

  Widget _controlsPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading('EVERYDAY INTERACTIONS', 'Make it yours.',
            'Change the appearance, move a slider and find the finish that feels right. Every control works inside the glass.'),
        _glass(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your space',
              style: TextStyle(
                  color: _ink, fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('These controls change the scene you are looking at.',
              style: TextStyle(color: _quiet, height: 1.4)),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark appearance'),
              value: _dark,
              onChanged: (value) => setState(() => _dark = value)),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ambient highlights'),
              subtitle: Text(_motionOff
                  ? 'Paused by your reduced motion preference'
                  : 'A gentle movement across the surface'),
              value: _config.animateLight && !_motionOff,
              onChanged: _motionOff
                  ? null
                  : (value) => setState(
                      () => _config = _config.copyWith(animateLight: value))),
          const Divider(height: 28),
          _slider('Edge bend', _config.refractionStrength, 0, 0.12,
              (value) => _tune(_config.copyWith(refractionStrength: value))),
        ])),
        const SizedBox(height: 18),
        _panel(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.touch_app_rounded, color: _ink),
          const SizedBox(width: 12),
          Expanded(
              child: Text(
                  'Scroll, tap and use the keyboard. The same controls keep their focus, touch targets and actions.',
                  style: TextStyle(color: _quiet, height: 1.5))),
        ])),
      ]);

  Widget _comfortPage() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading('ACCESSIBILITY & COMFORT', 'Clarity comes first.',
            'Preview a quieter material. These choices stay inside this demo and do not change your device settings.'),
        _panel(
            child: Column(children: [
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce transparency'),
              subtitle:
                  const Text('Use a solid surface behind labels and controls'),
              value: _reduceTransparency,
              onChanged: (value) =>
                  setState(() => _reduceTransparency = value)),
          const Divider(height: 20),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce motion'),
              subtitle:
                  const Text('Stop moving highlights and page animations'),
              value: _reduceMotion,
              onChanged: (value) => setState(() => _reduceMotion = value)),
          const Divider(height: 20),
          SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Increase contrast'),
              subtitle: const Text('Give text and controls an opaque backing'),
              value: _highContrast,
              onChanged: (value) => setState(() => _highContrast = value)),
        ])),
        const SizedBox(height: 20),
        _glass(
            child: Row(children: [
          Icon(Icons.visibility_rounded, size: 28, color: _ink),
          const SizedBox(width: 14),
          Expanded(
              child: Text(
                  'Your current comfort settings are applied to every glass surface in this preview.',
                  style: TextStyle(
                      color: _ink, height: 1.45, fontWeight: FontWeight.w600))),
        ])),
        const SizedBox(height: 18),
        Text(
            'System text size, reduced motion and high contrast are also respected. Turn a preview off to follow the system preference again.',
            style: TextStyle(color: _quiet, height: 1.5)),
      ]);

  Widget _panel({required Widget child}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _surface.withValues(alpha: _contrastOn ? 1 : 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _ink.withValues(alpha: 0.06))),
        child: child,
      );

  Widget _tuningPanel() => Container(
        key: _tuningKey,
        child: _panel(
            child: Column(children: [
          Row(children: [
            Expanded(
                child: Text('Fine adjustments',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800))),
            TextButton(
                onPressed: () => _chooseMaterial(_material),
                child: const Text('Reset')),
          ]),
          _slider('Softness', _config.blurSigma, 0, 30,
              (v) => _tune(_config.copyWith(blurSigma: v))),
          _slider('Edge bend', _config.refractionStrength, 0, 0.12,
              (v) => _tune(_config.copyWith(refractionStrength: v))),
          _slider('Roughness', _config.roughness, 0, 1,
              (v) => _tune(_config.copyWith(roughness: v))),
          _slider('Transmission', _config.transmission, 0, 1,
              (v) => _tune(_config.copyWith(transmission: v))),
          _slider('Refractive index', _config.refractiveIndex, 1, 2,
              (v) => _tune(_config.copyWith(refractiveIndex: v))),
          _slider('Thickness', _config.thickness, 0, 2,
              (v) => _tune(_config.copyWith(thickness: v))),
          _slider('Color separation', _config.dispersionStrength, 0, 2,
              (v) => _tune(_config.copyWith(dispersionStrength: v))),
          _slider('Coating', _config.coatStrength, 0, 1,
              (v) => _tune(_config.copyWith(coatStrength: v))),
          _slider('Absorption', _config.absorptionStrength, 0, 8,
              (v) => _tune(_config.copyWith(absorptionStrength: v))),
          const SizedBox(height: 10),
          ExpansionTile(
            expansionAnimationStyle:
                _motionOff ? AnimationStyle.noAnimation : null,
            tilePadding: EdgeInsets.zero,
            title: const Text('Developer details'),
            children: [
              ValueListenableBuilder<LiquidGlassDiagnostics?>(
                valueListenable: _diagnostics,
                builder: (context, value, _) => Text(
                    value == null
                        ? 'Surface details appear when glass is active.'
                        : '${value.activeSurfaceCount} surfaces · ${(value.estimatedBytes / 1048576).toStringAsFixed(1)} MiB current capture',
                    style: TextStyle(color: _quiet, fontSize: 11)),
              ),
              const SizedBox(height: 10)
            ],
          ),
        ])),
      );

  Widget _slider(String label, double value, double min, double max,
          ValueChanged<double> onChanged) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Text(label,
                      style:
                          TextStyle(color: _ink, fontWeight: FontWeight.w600))),
              Text(value.toStringAsFixed(2), style: TextStyle(color: _quiet))
            ]),
            Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                semanticFormatterCallback: (value) =>
                    '$label ${value.toStringAsFixed(2)}'),
          ]));

  Widget _navigation() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _glass(
          shape: const LiquidGlassShape.capsule(),
          padding: const EdgeInsets.all(5),
          child: Row(children: [
            _destination(_Section.materials, Icons.layers_rounded, 'Materials'),
            _destination(
                _Section.controls, Icons.touch_app_rounded, 'Controls'),
            _destination(
                _Section.comfort, Icons.accessibility_new_rounded, 'Comfort'),
          ]),
        ),
      );

  Widget _destination(_Section section, IconData icon, String label) {
    final selected = _section == section;
    return Expanded(
        child: Semantics(
            button: true,
            selected: selected,
            child: Tooltip(
              message: label,
              excludeFromSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _chooseSection(section),
                child: AnimatedContainer(
                  duration: _motionOff
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  decoration: BoxDecoration(
                      color: selected
                          ? _ink.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 21, color: _ink),
                    const SizedBox(height: 4),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500)),
                  ]),
                ),
              ),
            )));
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(
      {required this.dark, required this.scroll, required this.reduceMotion})
      : super(repaint: reduceMotion ? null : scroll);
  final bool dark;
  final ScrollController scroll;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final offset = !reduceMotion && scroll.hasClients ? scroll.offset : 0.0;
    final grid = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF0B4A76))
          .withValues(alpha: dark ? 0.06 : 0.045)
      ..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = -(offset % 32); y <= size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void orb(double x, double y, double radius, Color color) {
      final center = Offset(
          size.width * x,
          (size.height * y - offset * 0.16 + radius) %
                  (size.height + radius * 2) -
              radius);
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: dark ? 0.78 : 0.62),
                color.withValues(alpha: 0)
              ],
            ).createShader(Rect.fromCircle(center: center, radius: radius)));
    }

    orb(0.06, 0.15, 200, const Color(0xFFFF2D7A));
    orb(0.94, 0.36, 230, const Color(0xFF00BFEA));
    orb(0.15, 0.77, 210, const Color(0xFFFFAA38));
    orb(0.84, 0.96, 240, const Color(0xFF765BFF));
    final ribbon = Path()..moveTo(-40, size.height * 0.6);
    for (double x = -40; x <= size.width + 40; x += 8) {
      ribbon.lineTo(
          x, size.height * 0.6 + math.sin((x + offset * 0.3) / 65) * 30);
    }
    canvas.drawPath(
        ribbon,
        Paint()
          ..color = const Color(0xFF246BFD).withValues(alpha: dark ? 0.3 : 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.dark != dark ||
      oldDelegate.scroll != scroll ||
      oldDelegate.reduceMotion != reduceMotion;
}
