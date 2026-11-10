import 'dart:convert';
import 'dart:io';

import 'support/photo_accessibility_suite.dart';

void main() {
  final observations = <String, Map<String, Object?>>{};
  registerPhotoAccessibilityTests(
    loadPhoto: () => File('example/assets/blue_marble_2002.jpg').readAsBytes(),
    saveImage: (name, png) async {
      final directory = Directory('build/photo-accessibility');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(png);
    },
    onObservation: (name, data) {
      observations[name] = data;
      File('build/photo-accessibility/observations.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(observations));
    },
  );
}
