import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  group('LiquidGlassLightingController', () {
    test('initializes and notifies on tilt update', () {
      final controller = LiquidGlassLightingController();
      expect(controller.value, const Offset(-0.65, -0.75));

      var notified = false;
      controller.addListener(() => notified = true);

      controller.updateFromTilt(pitch: 0.5, roll: 0.3);
      expect(notified, isTrue);
      expect(controller.value.dx, isNotNull);
      expect(controller.value.dy, isNotNull);
    });

    test('updates from pointer position', () {
      final controller = LiquidGlassLightingController();
      controller.updateFromPointer(
          const Offset(150, 100), const Size(200, 200));

      expect(controller.value.dx, greaterThan(0));
      expect(controller.value.dy, closeTo(0, 0.01));
    });
  });

  group('LiquidGlassCard', () {
    testWidgets('renders child and applies padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassScope(
              background: ColoredBox(color: Colors.blue),
              child: LiquidGlassCard(
                padding: EdgeInsets.all(24),
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(LiquidGlassCard), findsOneWidget);
    });

    testWidgets('binds lightingController and updates dynamically',
        (tester) async {
      final controller = LiquidGlassLightingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassScope(
              background: const ColoredBox(color: Colors.blue),
              child: LiquidGlassCard(
                lightingController: controller,
                child: const Text('Dynamic Card'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dynamic Card'), findsOneWidget);
      controller.updateFromTilt(pitch: 0.8, roll: -0.4);
      await tester.pump();
      expect(controller.value, isNotNull);
    });
  });

  group('LiquidGlassButton', () {
    testWidgets('fires onPressed on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassScope(
              background: const ColoredBox(color: Colors.blue),
              child: LiquidGlassButton(
                onPressed: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.byType(LiquidGlassButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('handles custom foregroundColor and lightingController',
        (tester) async {
      final controller = LiquidGlassLightingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassScope(
              background: const ColoredBox(color: Colors.blue),
              child: LiquidGlassButton(
                onPressed: () {},
                foregroundColor: Colors.amber,
                lightingController: controller,
                child: const Text('Amber Button'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Amber Button'), findsOneWidget);
      controller.updateFromPointer(const Offset(50, 50), const Size(100, 40));
      await tester.pump();
    });

    testWidgets('handles disabled state when onPressed is null',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassScope(
              background: ColoredBox(color: Colors.blue),
              child: LiquidGlassButton(
                onPressed: null,
                child: Text('Disabled'),
              ),
            ),
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(LiquidGlassButton));
      final data = node.getSemanticsData();
      expect(data.label, 'Disabled');
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('LiquidGlassNavBar', () {
    testWidgets('switches selected item and fires onTap', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LiquidGlassScope(
                background: const ColoredBox(color: Colors.blue),
                child: LiquidGlassNavBar(
                  currentIndex: selected,
                  onTap: (index) => setState(() => selected = index),
                  items: const [
                    LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                    LiquidGlassNavItem(
                        icon: Icon(Icons.search), label: 'Search'),
                    LiquidGlassNavItem(
                        icon: Icon(Icons.settings), label: 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('adapts to light and dark theme brightness', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: LiquidGlassScope(
              background: const ColoredBox(color: Colors.white),
              child: LiquidGlassNavBar(
                currentIndex: 0,
                onTap: (_) {},
                items: const [
                  LiquidGlassNavItem(icon: Icon(Icons.home), label: 'Home'),
                  LiquidGlassNavItem(
                      icon: Icon(Icons.star), label: 'Favorites'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });
}
