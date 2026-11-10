/// Rejects incomplete or failed renderer exports even if the outer driver
/// reports success after a test-framework timeout.
void validateRendererReport(Map<String, dynamic> report) {
  if (report['fixtureVersion'] is! int) {
    throw StateError('Renderer report is missing its fixture metadata.');
  }

  final preceding = report['precedingContracts'];
  if (preceding != null) {
    if (preceding is! Map) {
      throw StateError('Preceding renderer contracts are missing.');
    }
    validateRendererReport(Map<String, dynamic>.from(preceding));
  }

  final errors = report['errors'];
  if (errors != null && (errors is! List || errors.isNotEmpty)) {
    throw StateError('Renderer contracts exported test failures.');
  }

  if (report.containsKey('requestedSeconds')) {
    final seconds = report['requestedSeconds'];
    if (seconds is! int || seconds < 10 || seconds > 600) {
      throw StateError('Endurance report has an invalid requested duration.');
    }
    if (report['completed'] != true) {
      throw StateError('Renderer endurance did not complete.');
    }
    final elapsed = report['elapsedMs'];
    if (elapsed is! num || !elapsed.isFinite || elapsed < seconds * 1000) {
      throw StateError(
          'Renderer endurance did not reach its requested duration.');
    }
    if (report['qualifiesTenMinuteWindow'] != (seconds >= 600)) {
      throw StateError(
          'Endurance qualification label contradicts its duration.');
    }
  } else {
    final observations = report['observations'];
    if (errors is! List || observations is! Map || observations.isEmpty) {
      throw StateError('Renderer contracts did not export their observations.');
    }
    if (report.containsKey('expectedObservationCount')) {
      final expected = report['expectedObservationCount'];
      if (expected is! int || expected < 1 || observations.length != expected) {
        throw StateError(
            'Renderer contracts did not complete every expected case.');
      }
    }
  }
}
