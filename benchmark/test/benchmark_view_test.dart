import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_benchmark/main.dart';

void main() {
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
