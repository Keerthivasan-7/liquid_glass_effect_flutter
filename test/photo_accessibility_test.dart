import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/photo_accessibility_suite.dart';

void main() {
  // Exercise desktop density too: a nominal 48px button can otherwise shrink.
  final observations = <String, Map<String, Object?>>{};
  registerPhotoAccessibilityTests(
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
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
