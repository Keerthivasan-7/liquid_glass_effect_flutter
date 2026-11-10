#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_refraction_strength;
uniform float u_fresnel_strength;
uniform float u_specular_strength;
uniform float u_chromatic_aberration;
uniform float u_thickness;
uniform float u_curvature;
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
uniform float u_refractive_index;
uniform float u_corner_smoothing;
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
uniform vec2 u_surface_origin;
uniform vec2 u_surface_size;
uniform float u_pixels_per_logical;
uniform sampler2D u_backdrop;

out vec4 frag_color;

const float PI = 3.141592653589793;

float p_length(vec2 v, float exponent) {
  vec2 a = pow(abs(v), vec2(exponent));
  return pow(a.x + a.y, 1.0 / exponent);
}

float rounded_rect_sdf(vec2 p, vec2 half_size, float radius, float exponent) {
  vec2 q = abs(p) - half_size + vec2(radius);
  return p_length(max(q, vec2(0.0)), exponent) +
      min(max(q.x, q.y), 0.0) - radius;
}

vec2 rounded_rect_gradient(vec2 p, vec2 half_size, float radius, float exponent) {
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

float safe_hash(vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
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

vec2 clamp_uv(vec2 uv, float scatter_radius) {
  vec2 half_texel = 0.5 / max(u_size, vec2(1.0));
  return clamp(uv, half_texel, vec2(1.0) - half_texel);
}

vec4 tap_backdrop(vec2 uv, vec2 offset, float scatter_radius) {
  vec2 size = max(u_size, vec2(1.0));
  vec2 pixel_offset = anisotropic_offset(offset * size);
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
  pixel_offset.y = -pixel_offset.y;
#endif
  return texture(u_backdrop, clamp_uv(uv + pixel_offset / size, scatter_radius));
}

vec4 sample_backdrop(vec2 uv, vec2 pixel, float scatter_radius) {
  vec4 center = texture(u_backdrop, clamp_uv(uv, scatter_radius));
  if (u_quality < 0.5 || scatter_radius < 0.25) return center;

  vec2 near_offset = pixel * scatter_radius * 0.38;
  vec2 diagonal = near_offset * 0.70710678;
  if (u_quality < 1.5) {
    vec4 color = center * 0.36;
    color += tap_backdrop(uv, vec2(near_offset.x, 0.0), scatter_radius) * 0.10;
    color += tap_backdrop(uv, vec2(-near_offset.x, 0.0), scatter_radius) * 0.10;
    color += tap_backdrop(uv, vec2(0.0, near_offset.y), scatter_radius) * 0.10;
    color += tap_backdrop(uv, vec2(0.0, -near_offset.y), scatter_radius) * 0.10;
    color += tap_backdrop(uv, diagonal, scatter_radius) * 0.06;
    color += tap_backdrop(uv, -diagonal, scatter_radius) * 0.06;
    color += tap_backdrop(uv, vec2(diagonal.x, -diagonal.y), scatter_radius) * 0.06;
    color += tap_backdrop(uv, vec2(-diagonal.x, diagonal.y), scatter_radius) * 0.06;
    return color;
  }

  vec2 far_offset = pixel * scatter_radius * 0.92;
  vec2 far_diagonal = far_offset * 0.70710678;
  vec4 color = center * 0.16;
  color += tap_backdrop(uv, vec2(near_offset.x, 0.0), scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(-near_offset.x, 0.0), scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(0.0, near_offset.y), scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(0.0, -near_offset.y), scatter_radius) * 0.07;
  color += tap_backdrop(uv, diagonal, scatter_radius) * 0.07;
  color += tap_backdrop(uv, -diagonal, scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(diagonal.x, -diagonal.y), scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(-diagonal.x, diagonal.y), scatter_radius) * 0.07;
  color += tap_backdrop(uv, vec2(far_offset.x, 0.0), scatter_radius) * 0.035;
  color += tap_backdrop(uv, vec2(-far_offset.x, 0.0), scatter_radius) * 0.035;
  color += tap_backdrop(uv, vec2(0.0, far_offset.y), scatter_radius) * 0.035;
  color += tap_backdrop(uv, vec2(0.0, -far_offset.y), scatter_radius) * 0.035;
  color += tap_backdrop(uv, far_diagonal, scatter_radius) * 0.035;
  color += tap_backdrop(uv, -far_diagonal, scatter_radius) * 0.035;
  color += tap_backdrop(uv, vec2(far_diagonal.x, -far_diagonal.y), scatter_radius) * 0.035;
  color += tap_backdrop(uv, vec2(-far_diagonal.x, far_diagonal.y), scatter_radius) * 0.035;
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
  float distance = min(
    length(lateral) * u_refraction_strength * u_thickness * shortest,
    u_max_displacement
  );
  return length(lateral) > 0.00001 ? normalize(lateral) * distance : vec2(0.0);
}

void main() {
  vec2 texture_frag = FlutterFragCoord().xy;
  float pixel_scale = max(u_pixels_per_logical, 0.0001);
  vec2 frag = (texture_frag - u_surface_origin) / pixel_scale;
  vec2 safe_size = max(u_surface_size, vec2(1.0));
  vec2 texture_size = max(u_size, vec2(1.0));
  vec2 half_size = safe_size * 0.5;
  vec2 p = frag - half_size;
  float shortest = max(min(safe_size.x, safe_size.y), 1.0);
  float exponent = mix(2.0, 8.0, clamp(u_corner_smoothing, 0.0, 1.0));
  float distance;
  vec2 edge_normal;

  if (u_shape > 1.5) {
    vec2 normalized = p / max(half_size, vec2(1.0));
    distance = (length(normalized) - 1.0) * shortest * 0.5;
    edge_normal = normalize(normalized + vec2(0.000001));
  } else {
    float radius = u_shape > 0.5
        ? shortest * 0.5
        : min(u_corner_radius, shortest * 0.5);
    distance = rounded_rect_sdf(p, half_size, radius, exponent);
    edge_normal = rounded_rect_gradient(p, half_size, radius, exponent);
  }

  float bevel = max(u_edge_width * shortest * 0.5, 1.5);
  float inward = clamp(-distance / bevel, 0.0, 1.0);
  float profile_power = mix(
    1.8,
    0.72,
    clamp(u_curvature * 0.5, 0.0, 1.0)
  );
  float height = pow(sin(inward * 0.5 * PI), profile_power);
  float edge_weight = 1.0 - height;
  float slope = edge_weight * mix(
    2.25,
    0.8,
    clamp(u_curvature * 0.5, 0.0, 1.0)
  );
  // Keep the convex surface normal consistent with the capture renderer.
  vec3 normal = normalize(vec3(edge_normal * slope, 1.0));

  vec2 interaction_delta = (frag - u_interaction_point) / shortest;
  float interaction_falloff = exp(
    -dot(interaction_delta, interaction_delta) * 12.0
  ) * clamp(u_interaction_strength, 0.0, 1.0);
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
        motion_normal,
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

  vec2 uv = texture_frag / texture_size;
  vec2 displacement_uv = displacement * pixel_scale / texture_size;
  vec2 red_uv = displacement_red * pixel_scale / texture_size;
  vec2 blue_uv = displacement_blue * pixel_scale / texture_size;
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
  vec2 pixel = pixel_scale / texture_size;
  vec2 transmitted_uv = uv + displacement_uv;
  vec4 color = sample_backdrop(transmitted_uv, pixel, scatter_radius);

  float legacy_dispersion = u_chromatic_aberration * shortest *
      edge_weight * edge_weight;
  if (u_dispersion_strength > 0.0 || legacy_dispersion > 0.0) {
    vec2 legacy_offset = edge_normal * legacy_dispersion * pixel;
#if defined(IMPELLER_TARGET_OPENGLES) && !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
    legacy_offset.y = -legacy_offset.y;
#endif
    vec4 red_sample = sample_backdrop(
      uv + red_uv + legacy_offset,
      pixel,
      scatter_radius
    );
    vec4 blue_sample = sample_backdrop(
      uv + blue_uv - legacy_offset,
      pixel,
      scatter_radius
    );
    color.r = red_sample.r;
    color.b = blue_sample.b;
  }

  float alpha = color.a;
  vec3 transmitted = alpha > 0.0001 ? color.rgb / alpha : vec3(0.0);
  float luminance = dot(transmitted, vec3(0.2126, 0.7152, 0.0722));
  transmitted = mix(vec3(luminance), transmitted, u_saturation);

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

  vec2 reflection_offset = -displacement_uv * (0.45 + u_roughness * 0.4) +
      normalize(-u_light_direction + vec2(0.000001)) * pixel *
          scatter_radius * 0.24;
  // A rough dielectric cannot return a pin-sharp environment reflection.
  // Reuse the anisotropic microfacet footprint at a smaller radius so the
  // reflection broadens with roughness while transmission stays independent.
  float reflection_radius = min(
    24.0,
    0.35 + u_roughness * u_roughness * shortest * 0.24 +
        u_coat_roughness * shortest * 0.035
  );
  vec4 reflected_sample = sample_backdrop(
    uv + reflection_offset,
    pixel,
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
  vec3 direct_specular = u_light_color.rgb * u_light_intensity * n_dot_l *
      (clamp(base_specular, 0.0, 4.0) * u_specular_strength +
       clamp(coat_specular, 0.0, 4.0) * u_coat_strength * interference) * 0.16;

  vec2 light_2d = normalize(-u_light_direction + vec2(0.000001));
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
  straight = mix(straight, u_tint.rgb, adaptive_tint);
  straight += direct_specular;
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
  frag_color = vec4(straight * alpha, alpha);
}
