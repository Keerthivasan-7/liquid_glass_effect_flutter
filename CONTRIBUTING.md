# Contributing

1. Reproduce visual changes in the example laboratory.
2. Add or update deterministic tests for configuration, geometry, and widget behavior.
3. Run formatting, analysis, tests, and the publish dry run.
4. For shader changes, test both Impeller and the portable fallback and include device, OS, Flutter version, renderer, surface size, quality, and frame timings.
5. Do not describe an effect as supported on a platform that was not tested.

Shader uniforms form a contract between Dart and GLSL. Update the appropriate
`_bindFilterUniforms`/`_bindCaptureUniforms`, shader declarations, and semantic
manifest in `test/shader_binding_test.dart` together. Count checks are only a
quick guard. Re-run shared pixel contracts and preserve backend-specific PNGs,
SDK/source manifests, actual paths and capture telemetry.

Use `example/integration_test/renderer_qualification_test.dart` for pixel and
ten-minute lifecycle qualification, and the benchmark integration matrix for
raw repeated measurements. Record incomplete runs instead of replacing them
with favorable results. The [milestone plan](doc/VERIFIED_PORTABLE_RENDERER_PLAN.md)
and [performance protocol](doc/PERFORMANCE.md) define the acceptance gates.
