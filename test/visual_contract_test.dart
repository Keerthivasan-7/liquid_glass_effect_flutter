import 'dart:io';

import 'support/renderer_contract_suite.dart';

void main() => registerRendererContractTests(saveImage: (name, png) async {
      final output = File('build/renderer-visuals/$name.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(png);
    });
