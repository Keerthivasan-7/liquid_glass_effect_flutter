import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/renderer_fixture.dart';

void main() {
  testWidgets(
      'near-transparent tint approaches the untinted image continuously',
      (tester) async {
    Future<List<int>> sample(Color tint) async {
      await tester.pumpWidget(MaterialApp(
          home: RendererFixture(
              config: coordinateGlassConfig.copyWith(tint: tint))));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(RendererFixture.boundaryKey));
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                  .buffer
                  .asUint8List();
          final index = (150 * image.width + 200) * 4;
          return data.sublist(index, index + 3);
        } finally {
          image.dispose();
        }
      }))!;
    }

    final reference = await sample(Colors.transparent);
    for (final component in <double>[0, 1]) {
      for (final alpha in <double>[0.0002, 0.001, 1 / 255]) {
        final tinted = await sample(Color.from(
            alpha: alpha, red: component, green: component, blue: component));
        for (var channel = 0; channel < 3; channel += 1) {
          expect((tinted[channel] - reference[channel]).abs(),
              lessThanOrEqualTo(3),
              reason:
                  'Near-zero tint must not introduce a visible color jump.');
        }
      }
    }
  });
}
