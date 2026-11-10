import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Explicit semantic binding manifest. Order comes from parsed GLSL; the test
// compares each resulting numeric slot with the actual Dart setter expression.
const _configFields = <String, String>{
  'u_refractive_index': 'refractiveIndex',
  'u_refraction_strength': 'refractionStrength',
  'u_fresnel_strength': 'fresnelStrength',
  'u_specular_strength': 'specularStrength',
  'u_chromatic_aberration': 'chromaticAberration',
  'u_thickness': 'thickness',
  'u_curvature': 'curvature',
  'u_corner_smoothing': 'cornerSmoothing',
  'u_edge_width': 'edgeWidth',
  'u_max_displacement': 'maxDisplacement',
  'u_blur_sigma': 'blurSigma',
  'u_vibrancy': 'vibrancy',
  'u_saturation': 'saturation',
  'u_noise': 'noise',
  'u_inner_shadow': 'innerShadow',
  'u_roughness': 'roughness',
  'u_transmission': 'transmission',
  'u_absorption_strength': 'absorptionStrength',
  'u_scattering_strength': 'scatteringStrength',
  'u_dispersion_strength': 'dispersionStrength',
  'u_abbe_number': 'abbeNumber',
  'u_environment_strength': 'environmentStrength',
  'u_coat_strength': 'coatStrength',
  'u_coat_roughness': 'coatRoughness',
  'u_coat_refractive_index': 'coatRefractiveIndex',
  'u_thin_film_thickness': 'thinFilmThickness',
  'u_thin_film_refractive_index': 'thinFilmRefractiveIndex',
  'u_thin_film_strength': 'thinFilmStrength',
  'u_anisotropy': 'anisotropy',
  'u_caustic_strength': 'causticStrength',
  'u_light_intensity': 'lightIntensity',
};

Map<String, List<String>> _manifest(bool capture) => <String, List<String>>{
      for (final field in _configFields.entries)
        field.key: <String>['config.${field.value}'],
      'u_tint': <String>['tint.r', 'tint.g', 'tint.b', 'tint.a'],
      'u_light_direction': <String>['light.dx', 'light.dy'],
      'u_absorption_color': <String>[
        'absorption.r',
        'absorption.g',
        'absorption.b',
        'absorption.a'
      ],
      'u_light_color': <String>[
        'lightColor.r',
        'lightColor.g',
        'lightColor.b',
        'lightColor.a'
      ],
      'u_anisotropy_axis': <String>['anisotropyAxis.dx', 'anisotropyAxis.dy'],
      'u_quality': <String>['config.quality.index.toDouble()'],
      'u_corner_radius': <String>[
        capture
            ? '_shape.resolvedRadius(size)'
            : 'widget.shape.resolvedRadius(size)'
      ],
      'u_shape': <String>[
        capture ? '_shape.shaderValue' : 'widget.shape.shaderValue'
      ],
      'u_time': <String>[capture ? '_animationValue' : '_animation.value'],
      'u_interaction_point': <String>[
        capture ? '_interactionPoint.dx' : 'motion.point.dx',
        capture ? '_interactionPoint.dy' : 'motion.point.dy'
      ],
      'u_interaction_strength': <String>[
        capture ? '_interactionStrength' : 'motion.interactionStrength'
      ],
      'u_motion_velocity': <String>[
        capture ? '_interactionVelocity.dx' : 'motion.velocity.dx',
        capture ? '_interactionVelocity.dy' : 'motion.velocity.dy'
      ],
      'u_motion_strength': <String>[
        capture ? '_motionStrength' : 'motion.motionStrength'
      ],
      if (capture) ...<String, List<String>>{
        'u_wave_0': <String>[
          r'_waves.$1.origin.dx',
          r'_waves.$1.origin.dy',
          r'_waves.$1.age'
        ],
        'u_wave_1': <String>[
          r'_waves.$2.origin.dx',
          r'_waves.$2.origin.dy',
          r'_waves.$2.age'
        ],
        'u_blend_radius': <String>['field?.blendRadius ?? 0'],
        'u_capsule_radii': <String>[
          for (var i = 0; i < 4; i++) 'field?.member($i)?.radius ?? 0'
        ],
        'u_capsule_0': <String>[
          'field?.member(0)?.center.dx ?? 0',
          'field?.member(0)?.center.dy ?? 0',
          'field?.member(0)?.spine.dx ?? 0',
          'field?.member(0)?.spine.dy ?? 0'
        ],
        'u_capsule_1': <String>[
          'field?.member(1)?.center.dx ?? 0',
          'field?.member(1)?.center.dy ?? 0',
          'field?.member(1)?.spine.dx ?? 0',
          'field?.member(1)?.spine.dy ?? 0'
        ],
        'u_capsule_2': <String>[
          'field?.member(2)?.center.dx ?? 0',
          'field?.member(2)?.center.dy ?? 0',
          'field?.member(2)?.spine.dx ?? 0',
          'field?.member(2)?.spine.dy ?? 0'
        ],
        'u_capsule_3': <String>[
          'field?.member(3)?.center.dx ?? 0',
          'field?.member(3)?.center.dy ?? 0',
          'field?.member(3)?.spine.dx ?? 0',
          'field?.member(3)?.spine.dy ?? 0'
        ],
        'u_surface_size': <String>['size.width', 'size.height'],
        'u_scope_size': <String>['scopeSize.width', 'scopeSize.height'],
        'u_scope_origin': <String>['origin.dx', 'origin.dy'],
        'u_image_pixel_size': <String>[
          'image.width.toDouble()',
          'image.height.toDouble()'
        ],
        'u_surface_to_scope': <String>[
          'surfaceTransform[0]',
          'surfaceTransform[1]',
          'surfaceTransform[4]',
          'surfaceTransform[5]'
        ],
      },
      if (!capture) ...<String, List<String>>{
        'u_wave_0': <String>[
          '_wave(0).origin.dx',
          '_wave(0).origin.dy',
          '_wave(0).age'
        ],
        'u_wave_1': <String>[
          '_wave(1).origin.dx',
          '_wave(1).origin.dy',
          '_wave(1).age'
        ],
        'u_surface_origin': <String>[
          'screenOrigin.dx * pixelsPerLogical',
          'screenOrigin.dy * pixelsPerLogical'
        ],
        'u_surface_size': <String>['size.width', 'size.height'],
        'u_pixels_per_logical': <String>['pixelsPerLogical'],
      },
    };

void main() {
  for (final capture in <bool>[false, true]) {
    final label = capture ? 'capture' : 'filter';
    test('$label uniform names, types, order, and Dart values match', () {
      final shader =
          File('shaders/liquid_glass${capture ? '_capture' : ''}.frag')
              .readAsStringSync();
      final declarations =
          RegExp(r'^uniform (float|vec[234]|sampler2D) (\w+);', multiLine: true)
              .allMatches(shader)
              .toList();
      final manifest = _manifest(capture);
      final expected = <int, String>{};
      final names = <String>[];
      var slot = 0;
      for (final declaration in declarations) {
        final type = declaration[1]!;
        final name = declaration[2]!;
        if (type == 'sampler2D') {
          expect(name, capture ? 'u_capture' : 'u_backdrop');
          expect(shader, isNot(contains('uniform vec2 ${name}_size;')),
              reason: 'Skia generates a sampler-size uniform with this name');
          continue;
        }
        if (!capture && name == 'u_size') {
          expect(slot, 0);
          expect(type, 'vec2');
          slot += 2;
          continue;
        }
        names.add(name);
        final values = manifest[name];
        expect(values, isNotNull, reason: '$name has no binding manifest');
        final width = type == 'float' ? 1 : int.parse(type.substring(3));
        expect(values!.length, width, reason: '$name changed type');
        for (final value in values) {
          expected[slot++] = value;
        }
      }
      expect(names, unorderedEquals(manifest.keys),
          reason: 'A uniform was removed, duplicated, or renamed');

      final dart = File('lib/src/widgets/liquid_glass.dart').readAsStringSync();
      final method = _methodBody(
          dart, capture ? '_bindCaptureUniforms' : '_bindFilterUniforms');
      final setters =
          RegExp(r'^\s*\.\.setFloat\((\d+),\s*(.+)\);?\s*$', multiLine: true)
              .allMatches(method)
              .toList();
      final actual = <int, String>{};
      for (final setter in setters) {
        final index = int.parse(setter[1]!);
        expect(actual.containsKey(index), isFalse,
            reason: 'Slot $index is bound twice');
        actual[index] = setter[2]!.replaceAll('_config.', 'config.').trim();
      }
      expect(actual, expected);
      expect(setters.length, expected.length);
      if (capture) expect(method, contains('setImageSampler(0, image)'));
    });

    test(
        '$label uses pixel-space anisotropy and version-aware GLES orientation',
        () {
      final shader =
          File('shaders/liquid_glass${capture ? '_capture' : ''}.frag')
              .readAsStringSync();
      expect(shader, contains('anisotropic_offset(offset * size)'));
      expect(shader, isNot(contains('#ifdef IMPELLER_TARGET_OPENGLES')));
      expect(
          shader,
          contains(
              '#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)'));
      expect(shader, contains('0.5 / max('));
    });
  }
}

String _methodBody(String source, String name) {
  final start = source.indexOf('void $name(');
  expect(start, greaterThanOrEqualTo(0));
  final open = source.indexOf('{', start);
  var depth = 1;
  for (var i = open + 1; i < source.length; i += 1) {
    if (source[i] == '{') depth += 1;
    if (source[i] == '}') depth -= 1;
    if (depth == 0) return source.substring(open + 1, i);
  }
  throw StateError('Unclosed method $name');
}
