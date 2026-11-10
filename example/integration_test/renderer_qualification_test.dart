import 'dart:ui' as ui;

import 'renderer_contract_test.dart' as contracts;
import 'renderer_soak_test.dart' as soak;

/// Runs the pixel contracts and the ten-minute lifecycle check in one binary.
void main() {
  final mode = Uri.parse(ui.PlatformDispatcher.instance.defaultRouteName)
      .queryParameters['mode'];
  if (mode != 'soak') contracts.main();
  if (mode != 'contracts') soak.main();
}
