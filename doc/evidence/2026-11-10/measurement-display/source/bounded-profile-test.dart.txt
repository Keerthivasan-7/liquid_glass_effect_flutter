
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_benchmark/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('isolated measurement-display profile', (tester) async {
    final result = Completer<Map<String, Object?>>();
    await tester.pumpWidget(BenchmarkApp(
      scenario: const BenchmarkScenario(BenchmarkCase.ordinary),
      onResult: result.complete,
    ));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 20)));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 4)));
    await binding.traceAction(() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    }, streams: <String>['Dart', 'GC']);
    final report = (await tester.runAsync(() => result.future.timeout(const Duration(seconds: 40))))!;
    binding.reportData!['benchmark'] = report;
    binding.reportData!['profileFreezeHud'] = const bool.fromEnvironment('PROFILE_FREEZE_HUD');
    binding.reportData!['scope'] = 'Short desktop diagnostic with tracing overhead; not a qualified matrix or phone speedup result.';
    binding.reportData!['completed'] = report['measurementComplete'] == true;
    debugPrint('PROFILE_RESULT stopReason=${report['stopReason']} complete=${report['measurementComplete']}');
    expect(report['measurementComplete'], isTrue);
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(minutes: 3)));
}
