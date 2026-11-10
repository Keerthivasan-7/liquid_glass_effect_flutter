import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_benchmark/main.dart';

void main() {
  testWidgets('measurement display stays frozen while Stop remains usable',
      (tester) async {
    Map<String, Object?>? result;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BenchmarkApp(
        scenario: const BenchmarkScenario(BenchmarkCase.ordinary),
        onResult: (value) => result = value));
    await tester.pump();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final progress = find.text('Measuring… results appear when complete.');
    final display = find.byType(ValueListenableBuilder<int>);
    final labelBefore = tester.widget<Text>(progress);
    Widget? displayBefore;
    tester.element(display).visitChildElements((element) {
      displayBefore = element.widget;
    });
    await tester.pump(const Duration(seconds: 1));
    Widget? displayAfter;
    tester.element(display).visitChildElements((element) {
      displayAfter = element.widget;
    });
    expect(displayAfter, same(displayBefore),
        reason: 'The measurement display must not periodically rebuild.');
    expect(tester.widget<Text>(progress), same(labelBefore));
    tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Stop'))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(result, isNotNull);
    expect(result!['measurementComplete'], isFalse);
    expect(result!['metadata'], containsPair('benchmarkProtocolVersion', 7));
    expect(result!['metadata'], containsPair('hudRefreshHz', 0));
    expect(result!['metadata'], containsPair('idleHudRefreshHz', 4));
    await tester.pumpWidget(const SizedBox());
  });

  for (final disturbance in <String>['viewport', 'focus']) {
    testWidgets('$disturbance change invalidates an active measurement',
        (tester) async {
      Map<String, Object?>? result;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpWidget(BenchmarkApp(
          scenario: const BenchmarkScenario(BenchmarkCase.ordinary),
          onResult: (value) => result = value));
      await tester.tap(find.widgetWithText(FilledButton, 'Start'));
      await tester.pump();
      if (disturbance == 'viewport') {
        tester.view.physicalSize = const Size(1000, 800);
      } else {
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      }
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(result, isNotNull);
      expect(
          result!['stopReason'],
          disturbance == 'viewport'
              ? 'view-metrics-changed'
              : 'inactive-window');
      expect(result!['measurementComplete'], isFalse);
      expect(result!['qualifiedMeasurement'], isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
