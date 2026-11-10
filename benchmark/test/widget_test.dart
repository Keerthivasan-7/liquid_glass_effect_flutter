import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_benchmark/main.dart';

void main() {
  testWidgets('benchmark harness renders metrics and a selectable case',
      (tester) async {
    await tester.pumpWidget(const BenchmarkApp());
    await tester.pump();

    expect(find.textContaining('Path:'), findsOneWidget);
    expect(find.textContaining('Capture:'), findsOneWidget);
    expect(find.textContaining('Build p50/p90/p99:'), findsOneWidget);
    expect(find.textContaining('Raster p50/p90/p99:'), findsOneWidget);
    expect(find.textContaining('Raster misses'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
