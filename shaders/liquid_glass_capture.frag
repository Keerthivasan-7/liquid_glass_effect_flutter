#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_surface_size;
uniform vec2 u_scope_size;
uniform vec2 u_scope_origin;
uniform float u_refractive_index;
uniform float u_refraction_strength;
uniform float u_fresnel_strength;
uniform float u_specular_strength;
uniform float u_chromatic_aberration;
uniform float u_thickness;
uniform float u_curvature;
uniform float u_corner_smoothing;
uniform float u_edge_width;
uniform float u_max_displacement;
uniform float u_blur_sigma;
uniform float u_saturation;
uniform vec4 u_tint;
uniform vec2 u_light_direction;
uniform float u_noise;
uniform float u_quality;
uniform float u_corner_radius;
uniform float u_shape;
uniform float u_time;
uniform vec2 u_interaction_point;
uniform float u_interaction_strength;
uniform float u_inner_shadow;
uniform float u_roughness;
uniform float u_transmission;
uniform vec4 u_absorption_color;
uniform float u_absorption_strength;
uniform float u_scattering_strength;
uniform float u_dispersion_strength;
uniform float u_abbe_number;
uniform float u_environment_strength;
uniform float u_coat_strength;
uniform float u_coat_roughness;
uniform float u_coat_refractive_index;
uniform float u_thin_film_thickness;
uniform float u_thin_film_refractive_index;
uniform float u_thin_film_strength;
uniform float u_anisotropy;
uniform vec2 u_anisotropy_axis;
uniform float u_caustic_strength;
uniform vec4 u_light_color;
uniform float u_light_intensity;
uniform vec2 u_motion_velocity;
uniform float u_motion_strength;
uniform vec2 u_image_pixel_size;
uniform vec4 u_surface_to_scope;
uniform sampler2D u_capture;

out vec4 frag_color;

uniform float u_vibrancy;
uniform vec3 u_wave_0;
uniform vec3 u_wave_1;
uniform float u_blend_radius;
uniform vec4 u_capsule_0;
uniform vec4 u_capsule_1;
uniform vec4 u_capsule_2;
uniform vec4 u_capsule_3;

const float PI = 3.141592653589793;

float safe_hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float p_length(vec2 v, float exponent) {
  vec2 a = pow(abs(v), vec2(exponent));
  return pow(a.x + a.y, 1.0 / exponent);
}

float rounded_rect_sdf(vec2 p, vec2 half_size, float radius, float exponent) {
  vec2 q = abs(p) - half_size + vec2(radius);
  return p_length(max(q, vec2(0.0)), exponent) +
      min(max(q.x, q.y), 0.0) - radius;
}

vec2 sdf_gradient(vec2 p, vec2 half_size, float radius, float exponent) {
  vec2 q = abs(p) - half_size + vec2(radius);
  vec2 outside = max(q, vec2(0.0));
  float powered = max(
    pow(outside.x, exponent) + pow(outside.y, exponent),
    0.000001
  );
  float scale = pow(powered, 1.0 / exponent - 1.0);
  vec2 gradient = pow(outside, vec2(exponent - 1.0)) * scale * sign(p);
  if (dot(outside, outside) < 0.000001) {
    gradient = abs(q.x) < abs(q.y)
        ? vec2(sign(p.x), 0.0)
        : vec2(0.0, sign(p.y));
  }
  return normalize(gradient + vec2(0.000001));
}

vec2 rotate_2d(vec2 value, vec2 axis) {
  return mat2(axis.x, -axis.y, axis.y, axis.x) * value;
}

vec2 anisotropic_offset(vec2 offset) {
  float amount = clamp(u_anisotropy, -0.95, 0.95);
  vec2 local = rotate_2d(offset, vec2(u_anisotropy_axis.x, -u_anisotropy_axis.y));
  float stretch = 1.0 + abs(amount) * 1.75;
  local *= amount >= 0.0 ? vec2(stretch, 1.0 / stretch)
                         : vec2(1.0 / stretch, stretch);
  return rotate_2d(local, u_anisotropy_axis);
}

vec2 soft_clamp(vec2 uv) {
  // u_scope_size is logical crop size; u_image_pixel_size is the actual rounded
  // image size. Clamp to real edge texel centers at every capture scale.
  vec2 half_texel = 0.5 / max(u_image_pixel_size, vec2(1.0));
  return clamp(uv, half_texel, vec2(1.0) - half_texel);
}

vec2 scope_offset(vec2 local_offset) {
  return vec2(
    dot(u_surface_to_scope.xz, local_offset),
    dot(u_surface_to_scope.yw, local_offset)
  );
}

vec4 tap_capture(vec2 uv, vec2 offset, float scatter_radius) {
  vec2 size = max(u_scope_size, vec2(1.0));
  // Rotate/stretch in logical pixels, then convert to UVs. Applying this
  // matrix in normalized UV space makes the footprint aspect-dependent.
  vec2 pixel_offset = scope_offset(anisotropic_offset(offset * size));
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
  pixel_offset.y = -pixel_offset.y;
#endif
  return texture(
    u_capture,
    soft_clamp(uv + pixel_offset / size)
  );
}

vec4 sample_capture(vec2 uv, vec2 pixel, float scatter_radius) {
  vec4 center = texture(u_capture, soft_clamp(uv));
  if (u_quality < 0.5 || scatter_radius < 0.25) return center;

  vec2 near_offset = pixel * scatter_radius * 0.38;
  vec2 diagonal = near_offset * 0.70710678;
  if (u_quality < 1.5) {
    vec4 color = center * 0.36;
    color += tap_capture(uv, vec2(near_offset.x, 0.0), scatter_radius) * 0.10;
    color += tap_capture(uv, vec2(-near_offset.x, 0.0), scatter_radius) * 0.10;
    color += tap_capture(uv, vec2(0.0, near_offset.y), scatter_radius) * 0.10;
    color += tap_capture(uv, vec2(0.0, -near_offset.y), scatter_radius) * 0.10;
    color += tap_capture(uv, diagonal, scatter_radius) * 0.06;
    color += tap_capture(uv, -diagonal, scatter_radius) * 0.06;
    color += tap_capture(uv, vec2(diagonal.x, -diagonal.y), scatter_radius) * 0.06;
    color += tap_capture(uv, vec2(-diagonal.x, diagonal.y), scatter_radius) * 0.06;
    return color;
  }

  vec2 far_offset = pixel * scatter_radius * 0.92;
  vec2 far_diagonal = far_offset * 0.70710678;
  vec4 color = center * 0.16;
  color += tap_capture(uv, vec2(near_offset.x, 0.0), scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(-near_offset.x, 0.0), scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(0.0, near_offset.y), scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(0.0, -near_offset.y), scatter_radius) * 0.07;
  color += tap_capture(uv, diagonal, scatter_radius) * 0.07;
  color += tap_capture(uv, -diagonal, scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(diagonal.x, -diagonal.y), scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(-diagonal.x, diagonal.y), scatter_radius) * 0.07;
  color += tap_capture(uv, vec2(far_offset.x, 0.0), scatter_radius) * 0.035;
  color += tap_capture(uv, vec2(-far_offset.x, 0.0), scatter_radius) * 0.035;
  color += tap_capture(uv, vec2(0.0, far_offset.y), scatter_radius) * 0.035;
  color += tap_capture(uv, vec2(0.0, -far_offset.y), scatter_radius) * 0.035;
  color += tap_capture(uv, far_diagonal, scatter_radius) * 0.035;
  color += tap_capture(uv, -far_diagonal, scatter_radius) * 0.035;
  color += tap_capture(uv, vec2(far_diagonal.x, -far_diagonal.y), scatter_radius) * 0.035;
  color += tap_capture(uv, vec2(-far_diagonal.x, far_diagonal.y), scatter_radius) * 0.035;
  return color;
}

float dielectric_f0(float ior) {
  float ratio = (ior - 1.0) / (ior + 1.0);
  return ratio * ratio;
}

float fresnel_schlick(float cos_theta, float f0) {
  return f0 + (1.0 - f0) * pow(1.0 - clamp(cos_theta, 0.0, 1.0), 5.0);
}

float smith_g1(float n_dot_x, float roughness) {
  float r = roughness + 1.0;
  float k = r * r * 0.125;
  return n_dot_x / max(n_dot_x * (1.0 - k) + k, 0.0001);
}

float anisotropic_ggx(
  vec3 half_vector,
  vec3 normal,
  vec3 tangent,
  vec3 bitangent,
  float roughness,
  float anisotropy
) {
  float alpha = max(roughness * roughness, 0.0025);
  float aspect = sqrt(max(1.0 - 0.9 * abs(anisotropy), 0.1));
  float alpha_x = anisotropy >= 0.0 ? alpha / aspect : alpha * aspect;
  float alpha_y = anisotropy >= 0.0 ? alpha * aspect : alpha / aspect;
  float x = dot(half_vector, tangent) / alpha_x;
  float y = dot(half_vector, bitangent) / alpha_y;
  float z = max(dot(half_vector, normal), 0.0);
  float denominator = x * x + y * y + z * z;
  return 1.0 / max(PI * alpha_x * alpha_y * denominator * denominator, 0.0001);
}

vec3 thin_film_color(float cos_theta) {
  float optical_path = 4.0 * PI * u_thin_film_refractive_index *
      u_thin_film_thickness * max(cos_theta, 0.08);
  vec3 phase = optical_path / vec3(650.0, 510.0, 475.0);
  return 0.55 + 0.45 * cos(phase);
}

vec2 refracted_offset(vec3 normal, float ior, float shortest) {
  vec3 ray = refract(vec3(0.0, 0.0, -1.0), normal, 1.0 / max(ior, 1.0001));
  vec2 lateral = ray.xy / max(abs(ray.z), 0.2);
  float internal_path = u_thickness * shortest * (1.0 + 0.35 * (1.0 - abs(ray.z)));
  float distance = min(
    length(lateral) * u_refraction_strength * internal_path,
    u_max_displacement
  );
  return length(lateral) > 0.00001 ? normalize(lateral) * distance : vec2(0.0);
}

// Radial derivative of a compact sin^2 packet behind a moving wavefront.
vec2 wave_gradient(vec2 frag, vec3 wave) {
  if (wave.z < 0.0) return vec2(0.0);
  vec2 delta = frag - wave.xy;
  float r = length(delta);
  float phase = (wave.z * 245.0 - r) / 44.0;
  if (phase <= 0.0 || phase >= 1.0 || r < 0.001) return vec2(0.0);
  float decay = exp(-3.3 * wave.z) * (1.0 - smoothstep(0.70, 0.92, wave.z));
  return delta / r * (-0.33 * sin(2.0 * PI * phase) * decay);
}

// The xy components carry the gradient of the distance in z. The
// polynomial blend interpolates both, so the bridge has a single normal.
vec3 capsule_field(vec2 p, vec4 box) {
  vec2 half_size = box.zw * 0.5;
  float radius = min(half_size.x, half_size.y);
  vec2 d = p - (box.xy + half_size);
  vec2 span = half_size - radius;
  vec2 v = d - clamp(d, -span, span);
  float len = length(v);
  return vec3(v / max(len, 0.0001), len - radius);
}

vec3 join_field(vec3 a, vec3 b) {
  float k = u_blend_radius;
  if (k <= 0.0001) return a.z <= b.z ? a : b;
  float h = clamp(0.5 + 0.5 * (b.z - a.z) / k, 0.0, 1.0);
  return mix(b, a, h) - vec3(0.0, 0.0, k*h*(1.0-h));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 surface_size = max(u_surface_size, vec2(1.0));
  vec2 scope_size = max(u_scope_size, vec2(1.0));
  vec2 half_size = surface_size * 0.5;
  vec2 p = frag - half_size;
  float shortest = max(min(surface_size.x, surface_size.y), 1.0);
  float exponent = mix(2.0, 8.0, clamp(u_corner_smoothing, 0.0, 1.0));
  float radius = min(u_corner_radius, shortest * 0.5);
  float distance;
  vec2 edge_normal;

  float coverage = 1.0;
  if (u_capsule_0.z > 0.0) {
    vec3 field = capsule_field(frag, u_capsule_0);
    if (u_capsule_1.z > 0.0) field = join_field(field, capsule_field(frag, u_capsule_1));
    if (u_capsule_2.z > 0.0) field = join_field(field, capsule_field(frag, u_capsule_2));
    if (u_capsule_3.z > 0.0) field = join_field(field, capsule_field(frag, u_capsule_3));
    distance = field.z;
    edge_normal = field.xy;
    // Skia runtime effects do not expose screen-space derivatives.
    // Convert the local distance gradient using the inverse transpose.
    vec2 col_x = u_surface_to_scope.xy;
    vec2 col_y = u_surface_to_scope.zw;
    float det = col_x.x * col_y.y - col_y.x * col_x.y;
    vec2 scope_grad = vec2(col_y.y * field.x - col_x.y * field.y,
                           col_x.x * field.y - col_y.x * field.x) / max(abs(det), 0.0001);
    float aa = clamp(0.5 * length(scope_grad) * scope_size.x / u_image_pixel_size.x, 0.05, 2.0);
    coverage = 1.0 - smoothstep(-aa, aa, distance);
    if (coverage <= 0.0) { frag_color = vec4(0.0); return; }
  } else if (u_shape > 1.5) {
    vec2 normalized = p / max(half_size, vec2(1.0));
    distance = (length(normalized) - 1.0) * shortest * 0.5;
    edge_normal = normalize(normalized + vec2(0.000001));
  } else {
    if (u_shape > 0.5) radius = shortest * 0.5;
    distance = rounded_rect_sdf(p, half_size, radius, exponent);
    edge_normal = sdf_gradient(p, half_size, radius, exponent);
  }

  float bevel = max(u_edge_width * shortest * 0.5, 1.5);
  float inward = clamp(-distance / bevel, 0.0, 1.0);
  float profile_power = mix(
    1.8,
    0.72,
    clamp(u_curvature * 0.5, 0.0, 1.0)
  );
  float height = pow(sin(inward * 0.5 * PI), profile_power);
  float meniscus_lip = inward * exp(-inward * 3.6) * 0.32 * u_curvature;
  height = clamp(height + meniscus_lip, 0.0, 1.0);
  float edge_weight = 1.0 - height;
  float slope = edge_weight * mix(
    2.25,
    0.8,
    clamp(u_curvature * 0.5, 0.0, 1.0)
  );
  // A convex bevel's normal tilts outward. refract() then samples toward the
  // lens center; negating the gradient produces a concave/demagnifying lens.
  vec3 normal = normalize(vec3(edge_normal * slope, 1.0));

  vec2 interaction_delta = (frag - u_interaction_point) / shortest;
  float interaction_falloff = exp(
    -dot(interaction_delta, interaction_delta) * 12.0
  ) * clamp(u_interaction_strength, 0.0, 1.0);

  vec2 ripple_normal = wave_gradient(frag, u_wave_0) + wave_gradient(frag, u_wave_1);

  float motion_speed = min(length(u_motion_velocity), 1.5);
  vec2 motion_direction = motion_speed > 0.0001
      ? u_motion_velocity / motion_speed
      : vec2(0.0);
  vec2 wake_delta = interaction_delta + u_motion_velocity * 0.22;
  float motion_falloff = exp(-dot(wake_delta, wake_delta) * 6.5) *
      clamp(u_motion_strength, 0.0, 2.0);
  vec2 motion_normal = motion_direction * motion_speed * motion_falloff *
      mix(0.34, 0.82, edge_weight);
  normal = normalize(vec3(
    normal.xy - interaction_delta * interaction_falloff * 1.15 -
        ripple_normal - motion_normal,
    normal.z
  ));

  float dispersion_delta = (u_refractive_index - 1.0) /
      max(u_abbe_number, 5.0) * u_dispersion_strength;
  float ior_red = max(1.0001, u_refractive_index - dispersion_delta * 0.5);
  float ior_blue = u_refractive_index + dispersion_delta * 0.5;
  vec2 displacement = refracted_offset(normal, u_refractive_index, shortest) *
      mix(0.7, 1.3, edge_weight);
  vec2 displacement_red = refracted_offset(normal, ior_red, shortest) *
      mix(0.7, 1.3, edge_weight);
  vec2 displacement_blue = refracted_offset(normal, ior_blue, shortest) *
      mix(0.7, 1.3, edge_weight);

  vec2 uv = (u_scope_origin + scope_offset(frag)) / scope_size;
  vec2 displacement_uv = scope_offset(displacement) / scope_size;
  vec2 red_uv = scope_offset(displacement_red) / scope_size;
  vec2 blue_uv = scope_offset(displacement_blue) / scope_size;
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
  uv.y = 1.0 - uv.y;
  displacement_uv.y = -displacement_uv.y;
  red_uv.y = -red_uv.y;
  blue_uv.y = -blue_uv.y;
#endif

  float scatter_radius = min(
    u_blur_sigma + u_roughness * u_roughness * shortest * 0.35 * u_thickness +
        u_scattering_strength * shortest * 0.08,
    32.0
  );
  vec2 capture_pixel = 1.0 / scope_size;
  vec2 transmitted_uv = uv + displacement_uv;
  vec4 color = sample_capture(transmitted_uv, capture_pixel, scatter_radius);

  float legacy_dispersion = u_chromatic_aberration * shortest *
      edge_weight * edge_weight;
  if (u_dispersion_strength > 0.0 || legacy_dispersion > 0.0) {
    vec2 legacy_offset = scope_offset(edge_normal * legacy_dispersion) / scope_size;
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
    legacy_offset.y = -legacy_offset.y;
#endif
    vec2 red_vec = red_uv + legacy_offset;
    vec2 blue_vec = blue_uv - legacy_offset;
    float jitter = (safe_hash(frag * 1.61803) - 0.5) * 0.18;
    vec4 red_sample = sample_capture(
      uv + red_vec * (1.0 + jitter),
      capture_pixel,
      scatter_radius
    );
    vec4 blue_sample = sample_capture(
      uv + blue_vec * (1.0 + jitter),
      capture_pixel,
      scatter_radius
    );
    vec4 amber_sample = sample_capture(
      uv + red_vec * 0.46,
      capture_pixel,
      scatter_radius
    );
    vec4 cyan_sample = sample_capture(
      uv + blue_vec * 0.50,
      capture_pixel,
      scatter_radius
    );
    color.r = mix(red_sample.r, amber_sample.r, 0.26);
    color.g = color.g * 0.46 + amber_sample.g * 0.27 + cyan_sample.g * 0.27;
    color.b = mix(blue_sample.b, cyan_sample.b, 0.30);
  }

  float alpha = color.a;
  vec3 transmitted = alpha > 0.0001 ? color.rgb / alpha : vec3(0.0);
  float luminance = dot(transmitted, vec3(0.2126, 0.7152, 0.0722));
  transmitted = mix(vec3(luminance), transmitted, u_saturation);
  if (u_vibrancy > 0.0) {
    float high = max(max(transmitted.r, transmitted.g), transmitted.b);
    float low = min(min(transmitted.r, transmitted.g), transmitted.b);
    float headroom = max(0.0, min(1.0 - high, low));
    float gain = u_vibrancy * headroom * (1.0 - clamp(high - low, 0.0, 1.0));
    transmitted += (transmitted - vec3(luminance)) * gain;
  }

  vec3 view = vec3(0.0, 0.0, 1.0);
  float n_dot_v = clamp(dot(normal, view), 0.001, 1.0);
  float path_length = u_thickness * mix(0.42, 1.65, edge_weight) /
      max(n_dot_v, 0.2);
  vec3 absorption_coefficient = (vec3(1.0) - u_absorption_color.rgb) *
      u_absorption_strength;
  vec3 volume_transmittance = exp(-absorption_coefficient * path_length);
  transmitted *= volume_transmittance;
  float scatter = 1.0 - exp(-u_scattering_strength * path_length);
  transmitted = mix(
    transmitted,
    mix(vec3(luminance), u_light_color.rgb, 0.22),
    scatter * 0.42
  );
  vec3 straight = mix(u_tint.rgb, transmitted, u_transmission);

  vec2 reflection_light_offset = scope_offset(
    (-u_light_direction / max(length(u_light_direction), 1.0)) * scatter_radius * 0.24
  ) / scope_size;
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
  reflection_light_offset.y = -reflection_light_offset.y;
#endif
  vec2 reflection_offset = -displacement_uv * (0.45 + u_roughness * 0.4) + reflection_light_offset;
  // A rough dielectric cannot return a pin-sharp environment reflection.
  // Reuse the anisotropic microfacet footprint at a smaller radius so the
  // reflection broadens with roughness while transmission stays independent.
  float reflection_radius = min(
    24.0,
    0.35 + u_roughness * u_roughness * shortest * 0.24 +
        u_coat_roughness * shortest * 0.035
  );
  vec4 reflected_sample = sample_capture(
    uv + reflection_offset,
    capture_pixel,
    reflection_radius
  );
  vec3 reflected = reflected_sample.a > 0.0001
      ? reflected_sample.rgb / reflected_sample.a
      : vec3(0.0);
  float base_fresnel = fresnel_schlick(
    n_dot_v,
    dielectric_f0(u_refractive_index)
  );
  float reflection_weight = clamp(
    base_fresnel * u_fresnel_strength * u_environment_strength,
    0.0,
    0.92
  );
  straight = mix(straight, reflected, reflection_weight);

  vec3 light = normalize(vec3(-u_light_direction, 0.72));
  vec3 half_vector = normalize(light + view);
  float n_dot_l = max(dot(normal, light), 0.0);
  float v_dot_h = max(dot(view, half_vector), 0.0);
  vec2 tangent_xy = u_anisotropy_axis;
  vec3 tangent = normalize(vec3(
    tangent_xy,
    -dot(normal.xy, tangent_xy) / max(normal.z, 0.1)
  ));
  vec3 bitangent = normalize(cross(normal, tangent));
  float distribution = anisotropic_ggx(
    half_vector,
    normal,
    tangent,
    bitangent,
    max(u_roughness, 0.025),
    u_anisotropy
  );
  float geometry = smith_g1(n_dot_v, u_roughness) *
      smith_g1(n_dot_l, u_roughness);
  float micro_fresnel = fresnel_schlick(
    v_dot_h,
    dielectric_f0(u_refractive_index)
  );
  float base_specular = distribution * geometry * micro_fresnel /
      max(4.0 * n_dot_v * n_dot_l, 0.001);

  float coat_distribution = anisotropic_ggx(
    half_vector,
    normal,
    tangent,
    bitangent,
    max(u_coat_roughness, 0.025),
    0.0
  );
  float coat_geometry = smith_g1(n_dot_v, u_coat_roughness) *
      smith_g1(n_dot_l, u_coat_roughness);
  float coat_fresnel = fresnel_schlick(
    v_dot_h,
    dielectric_f0(u_coat_refractive_index)
  );
  float coat_specular = coat_distribution * coat_geometry * coat_fresnel /
      max(4.0 * n_dot_v * n_dot_l, 0.001);
  vec3 interference = mix(
    vec3(1.0),
    thin_film_color(n_dot_v),
    u_thin_film_strength * u_coat_strength
  );
  vec2 light_2d = (-u_light_direction / max(length(u_light_direction), 1.0));
  vec3 direct_specular = u_light_color.rgb * u_light_intensity * n_dot_l *
      (clamp(base_specular, 0.0, 4.0) * u_specular_strength +
       clamp(coat_specular, 0.0, 4.0) * u_coat_strength * interference) * 0.16;

  // Analytic Studio Softbox Specular Lobe (Photographic studio area light reflection)
  vec3 softbox_specular = vec3(0.0);
  if (u_specular_strength > 0.001 && u_coat_strength > 0.001) {
    vec3 r_vec = reflect(-view, normal);
    if (r_vec.z > 0.03) {
      float z_box = 1.35;
      float t_box = z_box / r_vec.z;
      vec2 q_box = (p / shortest) + r_vec.xy * t_box;
      vec2 box_center = -light_2d * 0.72;
      vec2 box_half_size = vec2(0.55, 0.35);
      vec2 d_box_vec = abs(q_box - box_center) - box_half_size;
      float d_box = length(max(d_box_vec, 0.0)) + min(max(d_box_vec.x, d_box_vec.y), 0.0);
      float penumbra = 0.08 + u_coat_roughness * 0.30 + u_roughness * 0.20;
      float softbox_int = (1.0 - smoothstep(-penumbra, penumbra, d_box)) * (z_box / sqrt(t_box * t_box + 1.0));
      float softbox_weight = softbox_int * coat_fresnel * u_coat_strength * u_specular_strength * 0.38;
      softbox_specular = u_light_color.rgb * u_light_intensity * softbox_weight;
    }
  }

  // Total Internal Reflection (TIR) Diamond-Grade Edge Luminescence
  float sin2_theta = 1.0 - n_dot_v * n_dot_v;
  float critical_sin2 = 1.0 / max(u_refractive_index * u_refractive_index, 1.001);
  float tir_intensity = smoothstep(critical_sin2 - 0.10, critical_sin2 + 0.05, sin2_theta) *
      pow(edge_weight, 1.5) * u_transmission * u_fresnel_strength;
  vec3 tir_glow = mix(u_light_color.rgb, vec3(1.0), 0.72) * tir_intensity * 0.36;

  float light_facing = clamp(
    dot(-edge_normal, light_2d) * 0.5 + 0.5,
    0.0,
    1.0
  );
  float silhouette = smoothstep(0.28, 1.0, edge_weight);
  float environment_rim = pow(light_facing, 2.4) * silhouette *
      u_environment_strength * base_fresnel;
  float caustic_band = exp(-pow((inward - 0.42) / 0.17, 2.0)) *
      pow(light_facing, 1.5) * u_caustic_strength * u_transmission;
  float directional_shadow = pow(1.0 - light_facing, 2.0) *
      smoothstep(0.42, 1.0, edge_weight);
  float interaction_glow = interaction_falloff * (1.0 - edge_weight * 0.35);
  float motion_glint = motion_falloff * motion_speed * silhouette *
      pow(max(dot(-edge_normal, motion_direction), 0.0), 2.0);

  float adaptive_tint = clamp(
    u_tint.a * mix(1.18, 0.68, luminance),
    0.0,
    0.34
  );
  if (adaptive_tint > 0.0001) {
    vec3 tint_target = u_tint.rgb;
    vec3 soft_tint = mix(
      straight - (vec3(1.0) - 2.0 * tint_target) * straight * (vec3(1.0) - straight),
      straight + (2.0 * tint_target - vec3(1.0)) * (sqrt(max(straight, vec3(0.0))) - straight),
      step(vec3(0.5), tint_target)
    );
    // Both tint responses fade with opacity, preserving the untinted limit.
    vec3 tint_response = mix(tint_target, soft_tint, 0.45);
    straight = mix(straight, tint_response, adaptive_tint);
  }
  straight += direct_specular + softbox_specular + tir_glow;
  straight += u_light_color.rgb * (
    environment_rim * 0.34 + caustic_band * 0.11 + interaction_glow * 0.05 +
        motion_glint * 0.09
  );
  // Define the unlit side by moving it toward the opposite of the sampled
  // environment. This is a broad, directional Fresnel bezel rather than a
  // fixed white stroke, so it remains visible on both light and dark scenes.
  vec3 contrast_target = mix(
    vec3(1.0),
    vec3(0.025),
    smoothstep(0.42, 0.72, luminance)
  );
  float bezel_strength = directional_shadow * u_inner_shadow *
      mix(0.16, 0.34, edge_weight);
  straight = mix(straight, contrast_target, bezel_strength);
  straight += (safe_hash(frag + vec2(u_time * 97.0)) - 0.5) * u_noise;
  straight = clamp(straight, vec3(0.0), vec3(1.0));
  frag_color = vec4(straight * alpha, alpha) * coverage;
}
