import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_showcase/main.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  testWidgets(
      'compact Studio supports large text, still controls and the gallery',
      (tester) async {
    tester.view.physicalSize = const Size(320, 660);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ShowcaseApp());
    await tester.pumpAndSettle();
    expect(find.text('Blue Marble'), findsOneWidget);
    Future<void> choose(String label) async {
      final target = find.text(label);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await choose('Separate lenses');
    expect(find.text('Join lenses'), findsOneWidget);
    await choose('Prism');
    await choose('Spectrum');
    await choose('Render details');
    await choose('Preview large text');
    expect(
        tester.getSize(find.byType(LiquidGlassNavBar)).height, greaterThan(68));
    await choose('Still motion');
    await choose('Replay join');
    expect(tester.binding.transientCallbackCount, 0);
    await choose('Gallery');
    expect(find.text('Find your finish'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Optics Studio'), findsOneWidget);
  });
}
