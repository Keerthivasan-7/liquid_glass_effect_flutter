import 'package:flutter_test/flutter_test.dart';

import '../example/test_driver/renderer_report_validation.dart';

Map<String, dynamic> contracts() => {
      'fixtureVersion': 5,
      'errors': <Object>[],
      'observations': {
        'convex-capture': {'activePath': 'capture'}
      },
    };

Map<String, dynamic> completedSoak({int seconds = 600}) => {
      'fixtureVersion': 5,
      'requestedSeconds': seconds,
      'qualifiesTenMinuteWindow': seconds >= 600,
      'completed': true,
      'elapsedMs': seconds * 1000 + 645,
    };

void main() {
  test('missing native result cannot become a successful run', () {
    expect(() => validateRendererReport({}), throwsStateError);
  });

  test('completed pixel contracts retain their normal success path', () {
    expect(() => validateRendererReport(contracts()), returnsNormally);
  });

  test('exported pixel assertion failures reject outer driver success', () {
    final report = contracts()..['errors'] = ['pixel mismatch'];
    expect(() => validateRendererReport(report), throwsStateError);
  });

  test('a timed-out partial soak rejects the observed false driver success',
      () {
    final report = {
      'fixtureVersion': 5,
      'requestedSeconds': 600,
      'qualifiesTenMinuteWindow': true,
      'completed': false,
      'samples': List.generate(320, (index) => {'elapsedMs': index * 1000}),
    };
    expect(() => validateRendererReport(report), throwsStateError);
  });

  test('completion flag cannot qualify a shortened endurance window', () {
    final report = completedSoak()..['elapsedMs'] = 599999;
    expect(() => validateRendererReport(report), throwsStateError);
  });

  test('a completed soak cannot hide preceding contract failures', () {
    final report = completedSoak()
      ..['precedingContracts'] = (contracts()..['errors'] = ['crop mismatch']);
    expect(() => validateRendererReport(report), throwsStateError);
  });

  test('complete combined qualification remains accepted', () {
    final report = completedSoak()..['precedingContracts'] = contracts();
    expect(() => validateRendererReport(report), returnsNormally);
  });

  test('short harness probes cannot claim ten-minute qualification', () {
    final report = completedSoak(seconds: 10);
    expect(() => validateRendererReport(report), returnsNormally);
    report['qualifiesTenMinuteWindow'] = true;
    expect(() => validateRendererReport(report), throwsStateError);
  });
}
