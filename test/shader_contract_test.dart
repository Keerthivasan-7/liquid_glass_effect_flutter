import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shader declares the engine-owned uniforms first', () {
    final source = File('shaders/liquid_glass.frag').readAsStringSync();
    final sizeIndex = source.indexOf('uniform vec2 u_size;');
    final samplerIndex = source.indexOf('uniform sampler2D u_backdrop;');
    expect(sizeIndex, greaterThanOrEqualTo(0));
    expect(samplerIndex, greaterThan(sizeIndex));
    expect(source, contains('FlutterFragCoord()'));
    expect(source, contains('clamp_uv'));
    expect(source, contains('IMPELLER_TARGET_OPENGLES'));
  });

  test('Dart and filter shader agree on 70 float slots', () {
    final source = File('shaders/liquid_glass.frag').readAsStringSync();
    expect(RegExp(r'uniform float ').allMatches(source).length, 38);
    expect(RegExp(r'uniform vec2 ').allMatches(source).length, 7);
    expect(RegExp(r'uniform vec4 ').allMatches(source).length, 3);
    expect(RegExp(r'uniform vec3 ').allMatches(source).length, 2);
    expect(source, contains('u_interaction_point'));
    expect(source, contains('interaction_falloff'));
    expect(source, contains('u_motion_velocity'));
    expect(source, contains('motion_glint'));
    expect(source, contains('diagonal'));
  });

  test('capture shader declares portable texture and 96 float slots', () {
    final source = File('shaders/liquid_glass_capture.frag').readAsStringSync();
    expect(source, contains('uniform sampler2D u_capture;'));
    expect(source, contains('refract('));
    expect(source, contains('u_refractive_index'));
    expect(source, contains('u_corner_smoothing'));
    expect(source, contains('u_inner_shadow'));
    expect(source, contains('FlutterFragCoord()'));
    expect(RegExp(r'uniform float ').allMatches(source).length, 38);
    expect(RegExp(r'uniform vec2 ').allMatches(source).length, 8);
    expect(RegExp(r'uniform vec4 ').allMatches(source).length, 9);
    expect(RegExp(r'uniform vec3 ').allMatches(source).length, 2);
    expect(source, contains('u_interaction_point'));
    expect(source, contains('interaction_falloff'));
    expect(source, contains('u_motion_velocity'));
    expect(source, contains('motion_glint'));
    expect(source, contains('diagonal'));
  });

  test('optical model uses layered dielectric physics', () {
    for (final path in <String>[
      'shaders/liquid_glass.frag',
      'shaders/liquid_glass_capture.frag',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('anisotropic_ggx'));
      expect(source, contains('fresnel_schlick'));
      expect(source, contains('volume_transmittance'));
      expect(source, contains('thin_film_color'));
      expect(source, contains('dispersion_delta'));
      expect(source, contains('environment_rim'));
      expect(source, contains('adaptive_tint'));
      expect(source, contains('caustic'));
      expect(source, contains('far_offset'));
      expect(source, isNot(contains('outer_rim')));
      expect(source, isNot(contains('inner_rim')));
    }
  });
}
