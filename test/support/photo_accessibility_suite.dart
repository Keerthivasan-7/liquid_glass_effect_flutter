import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

/// Separate from optical fixture v5: this tests an app's opaque reading mode.
const photoAccessibilityFixtureVersion = 1;
const photoAccessibilityCaseCount = 12;
const _boundaryKey = ValueKey<String>('photo-accessibility-image');

void registerPhotoAccessibilityTests({
  required Future<Uint8List> Function() loadPhoto,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  Future<void> Function(String name, Uint8List png)? saveImage,
  void Function(String name, Map<String, Object?> observation)? onObservation,
}) {
  for (final dark in <bool>[false, true]) {
    for (final highContrast in <bool>[false, true]) {
      for (final scale in <double>[1, 2, 3]) {
        final name = 'photo-${dark ? 'dark' : 'light'}-'
            '${highContrast ? 'high-contrast' : 'reduced-transparency'}-'
            '${scale.toInt()}x';
        testWidgets(name, (tester) async {
          final semantics = tester.ensureSemantics();
          final focus = FocusNode();
          final scroll = ScrollController();
          final opaque =
              dark ? const Color(0xFF223344) : const Color(0xFFF3F1EC);
          final expectedInk = dark ? Colors.white : Colors.black;
          final contrast = dark
              ? 1.05 / (opaque.computeLuminance() + 0.05)
              : (opaque.computeLuminance() + 0.05) / 0.05;
          LiquidGlassRenderPath? path;
          LiquidGlassDiagnostics? diagnostics;
          var activations = 0;
          try {
            final bytes = await tester.runAsync(loadPhoto);
            expect(bytes, isNotNull);
            final photo = MemoryImage(bytes!);
            await tester.pumpWidget(MaterialApp(
              initialRoute: '/',
              theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light),
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: SizedBox(
                    width: 320,
                    height: 568,
                    child: MediaQuery(
                      data: MediaQueryData(
                          size: const Size(320, 568),
                          textScaler: TextScaler.linear(scale),
                          highContrast: highContrast),
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: LiquidGlassScope(
                          onDiagnosticsChanged: (value) => diagnostics = value,
                          background: Image(
                              image: photo,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true),
                          child: SingleChildScrollView(
                            controller: scroll,
                            padding: const EdgeInsets.all(24),
                            child: LiquidGlass(
                              interactive: true,
                              semanticLabel: 'Reading panel',
                              config: const LiquidGlassConfig(
                                  renderer: LiquidGlassRenderer.capture),
                              accessibility: LiquidGlassAccessibilityPolicy(
                                  reduceTransparency: !highContrast,
                                  opaqueColor: opaque.withValues(alpha: 0.2)),
                              onRenderPathChanged: (value) => path = value,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    const Text('Explore Earth',
                                        style: TextStyle(fontSize: 24)),
                                    const SizedBox(height: 16),
                                    const Text(
                                        'An opaque reading surface keeps text clear over a detailed image.',
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(height: 16),
                                    Builder(
                                        builder: (context) => TextButton(
                                              focusNode: focus,
                                              // Material controls have explicit styles;
                                              // the app supplies their matching ink.
                                              style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      DefaultTextStyle.of(
                                                              context)
                                                          .style
                                                          .color,
                                                  visualDensity:
                                                      VisualDensity.standard,
                                                  minimumSize:
                                                      const Size(48, 48)),
                                              onPressed: () => activations += 1,
                                              child: const Text('Continue',
                                                  textAlign: TextAlign.center),
                                            )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
            // Decode real image data outside the fake test clock.
            await tester.runAsync(() =>
                precacheImage(photo, tester.element(find.byKey(_boundaryKey)))
                    .timeout(const Duration(seconds: 15)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(path, LiquidGlassRenderPath.fallback);
            expect(find.byType(BackdropFilter), findsNothing);
            expect(diagnostics!.captureCount, 0);
            expect(diagnostics!.retainedBytes, 0);
            expect(
                DefaultTextStyle.of(tester.element(find.text('Explore Earth')))
                    .style
                    .color,
                expectedInk);
            expect(contrast, greaterThanOrEqualTo(4.5));
            final buttonWidget =
                tester.widget<TextButton>(find.byType(TextButton));
            expect(
                buttonWidget.style!.foregroundColor!.resolve(<WidgetState>{}),
                expectedInk);

            final panel = tester.getRect(find.byType(LiquidGlass));
            final boundary = tester.getRect(find.byKey(_boundaryKey));
            final image = await _readImage(tester);
            // Padding above the title is clear of glyphs and edge lighting.
            final x = (panel.center.dx - boundary.left).floor();
            final y = (panel.top - boundary.top + 10).floor();
            final offset = (y * image.width + x) * 4;
            expect(image.rgba.sublist(offset, offset + 4), <int>[
              (opaque.toARGB32() >> 16) & 255,
              (opaque.toARGB32() >> 8) & 255,
              opaque.toARGB32() & 255,
              255
            ]);
            final photoSamples = <int>{};
            for (var row = 40; row < 520; row += 20) {
              final index = (row * image.width + 10) * 4;
              photoSamples.add((image.rgba[index] << 16) |
                  (image.rgba[index + 1] << 8) |
                  image.rgba[index + 2]);
            }
            expect(photoSamples.length, greaterThan(8),
                reason:
                    'The photographic source must be painted, not a placeholder.');
            await tester.runAsync(() async {
              await saveImage?.call('$name-top', image.png);
            });

            await tester.ensureVisible(find.byType(TextButton));
            focus.requestFocus();
            await tester.pumpAndSettle();
            expect(focus.hasFocus, isTrue);
            final button = tester.getRect(find.byType(TextButton));
            expect(button.width, greaterThanOrEqualTo(48));
            expect(button.height, greaterThanOrEqualTo(48));
            expect(button.top, greaterThanOrEqualTo(boundary.top));
            expect(button.bottom, lessThanOrEqualTo(boundary.bottom));
            await tester.sendKeyEvent(LogicalKeyboardKey.enter,
                physicalKey: PhysicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(activations, 1);
            final owner =
                tester.binding.renderViews.first.owner!.semanticsOwner!;
            var labels = 0;
            void visit(SemanticsNode node) {
              final data = node.getSemanticsData();
              if (data.label == 'Continue') {
                labels += 1;
                expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
              }
              node.visitChildren((child) {
                visit(child);
                return true;
              });
            }

            visit(owner.rootSemanticsNode!);
            expect(labels, 1);
            expect(tester.takeException(), isNull);
            final focused = await _readImage(tester);
            await tester.runAsync(() async {
              await saveImage?.call('$name-action', focused.png);
            });
            onObservation?.call(name, <String, Object?>{
              'fixtureVersion': photoAccessibilityFixtureVersion,
              'theme': dark ? 'dark' : 'light',
              'policy': highContrast
                  ? 'inherited-high-contrast'
                  : 'reduced-transparency',
              'textScale': scale,
              'viewport': <int>[320, 568],
              'contrastRatio': contrast,
              'path': path!.name,
              'captureCount': diagnostics!.captureCount,
              'scrollExtent': scroll.position.maxScrollExtent,
              'keyboardActivations': activations,
              'actionSemanticsCount': labels,
            });
          } finally {
            await tester.pumpWidget(const SizedBox());
            focus.dispose();
            scroll.dispose();
            semantics.dispose();
          }
        }, variant: variant);
      }
    }
  }
}

Future<({int width, Uint8List rgba, Uint8List png})> _readImage(
    WidgetTester tester) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundaryKey));
  return (await tester.runAsync(() async {
    final image = await boundary
        .toImage(pixelRatio: 1)
        .timeout(const Duration(seconds: 15));
    try {
      final rgba = await image
          .toByteData(format: ui.ImageByteFormat.rawRgba)
          .timeout(const Duration(seconds: 15));
      final png = await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(seconds: 15));
      return (
        width: image.width,
        rgba: rgba!.buffer.asUint8List(),
        png: png!.buffer.asUint8List()
      );
    } finally {
      image.dispose();
    }
  }))!;
}
