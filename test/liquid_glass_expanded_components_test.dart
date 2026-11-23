// Retained for the declared Flutter 3.32 minimum.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_effect_flutter/liquid_glass_effect_flutter.dart';

void main() {
  group('LiquidGlassThemeData & Presets', () {
    test('theme extension copyWith, equality and lerp work correctly', () {
      const theme1 = LiquidGlassThemeData(
        defaultConfig: LiquidGlassConfig.regular(),
      );
      final theme2 = theme1.copyWith(
        cardConfig: const LiquidGlassConfig.frosted(),
      );

      expect(theme1 == theme2, isFalse);
      expect(theme2.cardConfig, const LiquidGlassConfig.frosted());
      expect(theme2.defaultConfig, const LiquidGlassConfig.regular());

      final lerped = theme1.lerp(theme2, 0.75);
      expect(lerped, equals(theme2));
    });

    test('dark mode presets and adaptive helper', () {
      final dark = LiquidGlassPresets.regularDark;
      expect(dark.blurSigma, 6.5);

      final adaptiveLight =
          LiquidGlassPresets.adaptive(Brightness.light);
      final adaptiveDark =
          LiquidGlassPresets.adaptive(Brightness.dark);

      expect(adaptiveLight, const LiquidGlassConfig.regular());
      expect(adaptiveDark, LiquidGlassPresets.regularDark);

      final converted = const LiquidGlassConfig.clear().toDark();
      expect(converted.tint, const Color(0x30050A18));
    });
  });

  group('LiquidGlassSwitch', () {
    testWidgets('renders, animates, and notifies onChanged', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LiquidGlassSwitch(
                value: toggled,
                onChanged: (val) => setState(() => toggled = val),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassSwitch), findsOneWidget);
      expect(toggled, isFalse);

      await tester.tap(find.byType(LiquidGlassSwitch));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    });
  });

  group('LiquidGlassSlider', () {
    testWidgets('renders and handles drag changes', (tester) async {
      var sliderVal = 0.2;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 300,
                child: LiquidGlassSlider(
                  value: sliderVal,
                  onChanged: (val) => setState(() => sliderVal = val),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassSlider), findsOneWidget);

      await tester.drag(find.byType(LiquidGlassSlider), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(sliderVal, greaterThan(0.2));
    });
  });

  group('LiquidGlassTextField', () {
    testWidgets('renders input and captures user typing', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassTextField(
              controller: controller,
              hintText: 'Enter text...',
            ),
          ),
        ),
      );

      expect(find.text('Enter text...'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Hello Liquid Glass');
      await tester.pumpAndSettle();

      expect(controller.text, 'Hello Liquid Glass');
    });
  });

  group('LiquidGlassChip', () {
    testWidgets('renders label and reacts to selection and deletion',
        (tester) async {
      var selected = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => LiquidGlassChip(
                label: const Text('Filter Tag'),
                selected: selected,
                onSelected: (val) => setState(() => selected = val),
                onDeleted: () => setState(() => deleted = true),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Filter Tag'), findsOneWidget);

      await tester.tap(find.text('Filter Tag'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });

  group('LiquidGlassBottomSheet', () {
    testWidgets('renders child content and handle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassBottomSheet(
              child: Text('Sheet Content'),
            ),
          ),
        ),
      );

      expect(find.text('Sheet Content'), findsOneWidget);
      expect(find.byType(LiquidGlassBottomSheet), findsOneWidget);
    });
  });

  group('LiquidGlassDialog', () {
    testWidgets('renders title, content, and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassDialog(
              title: const Text('Confirm Action'),
              content: const Text('Are you sure you want to proceed?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('LiquidGlassTooltip', () {
    testWidgets('renders child and provides tooltip semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassTooltip(
              message: 'Help info',
              child: Icon(Icons.info),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byType(LiquidGlassTooltip), findsOneWidget);
    });
  });

  group('LiquidGlassAppBar', () {
    testWidgets('renders title and satisfies PreferredSizeWidget',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: LiquidGlassAppBar(
              title: Text('Glass Nav'),
            ),
            body: SizedBox.expand(),
          ),
        ),
      );

      expect(find.text('Glass Nav'), findsOneWidget);
      expect(find.byType(LiquidGlassAppBar), findsOneWidget);
    });
  });

  group('LiquidGlassFAB', () {
    testWidgets('renders standard and extended FAB', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: LiquidGlassFAB.extended(
              icon: const Icon(Icons.add),
              label: const Text('Create'),
              onPressed: () => pressed = true,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );

      expect(find.text('Create'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('LiquidGlassDropdown & LiquidGlassListTile', () {
    testWidgets('renders dropdown and list tile', (tester) async {
      String? selectedVal = 'Item 1';
      var tileTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                LiquidGlassDropdown<String>(
                  value: selectedVal,
                  items: const <LiquidGlassDropdownItem<String>>[
                    LiquidGlassDropdownItem<String>(
                      value: 'Item 1',
                      child: Text('Item 1'),
                    ),
                    LiquidGlassDropdownItem<String>(
                      value: 'Item 2',
                      child: Text('Item 2'),
                    ),
                  ],
                  onChanged: (val) => selectedVal = val,
                ),
                LiquidGlassListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('General Settings'),
                  subtitle: const Text('Manage your preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => tileTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('General Settings'), findsOneWidget);
      expect(find.text('Manage your preferences'), findsOneWidget);

      await tester.tap(find.text('General Settings'));
      await tester.pumpAndSettle();
      expect(tileTapped, isTrue);
    });
  });
}
