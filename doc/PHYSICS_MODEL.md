# Physical optics model

The runtime shader is a real-time, screen-space dielectric approximation. It
cannot trace rays through 3D geometry like Blender Cycles, but it follows the
same separation of concerns: a transmissive base, dielectric reflection,
volume attenuation/scatter, an optional coat, and an optional thin film.

## Blender-derived design map

The model follows the public Blender/OpenPBR vocabulary rather than copying
Blender source code:

- Blender's Glass BSDF mixes refraction and reflection at grazing angles and
  uses roughness to soften both. This maps to `refractiveIndex`,
  `transmission`, `roughness`, and Schlick Fresnel.
- Blender's Principled transmission layer includes specular reflection and
  refraction. A separate coat has its own weight, roughness, and IOR. This maps
  to `coatStrength`, `coatRoughness`, and `coatRefractiveIndex`.
- Blender's volume model uses per-channel absorption coefficients and
  scattering density. This shader applies Beer–Lambert attenuation along an
  angle- and thickness-dependent path, then adds low-frequency forward scatter.
- Blender's dispersion relates spectral separation to IOR and Abbe number.
  This shader calculates red, green, and blue refracted offsets from
  `dispersionStrength / abbeNumber` and filters every channel consistently.
- Blender's anisotropic glossy model stretches the microfacet distribution
  along a rotated tangent. This shader uses an anisotropic GGX normal
  distribution for direct highlights and the same tangent for transmission
  scatter.
- Blender's thin-film layer varies reflection color with view angle, film IOR,
  and nanometer thickness. This shader evaluates an RGB wavelength
  approximation for the coat response.

Primary references:

- <https://docs.blender.org/manual/en/dev/render/shader_nodes/shader/principled.html>
- <https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/glass.html>
- <https://docs.blender.org/manual/en/5.3/render/shader_nodes/shader/volume_coefficients.html>
- <https://developer.blender.org/docs/release_notes/4.2/cycles/>

## Evaluation sequence

1. Evaluate the rounded-shape signed distance field and derive a continuous
   lens normal from the thickness profile.
2. Bend the backdrop coordinate with GLSL `refract` and a bounded Snell offset.
3. Re-evaluate the offset for red and blue using IOR spread derived from Abbe
   number; green uses the central IOR.
4. Integrate a rough, optionally anisotropic transmission lobe with normalized
   1-, 9-, or 17-tap kernels.
5. Apply Beer–Lambert attenuation:
   `T = exp(-(1 - absorptionColor) * absorptionStrength * pathLength)`.
6. Sample a reflected environment proxy in the opposite optical direction,
   broaden that reflection with the roughness/anisotropy footprint, and mix it
   with transmission using dielectric Fresnel.
7. Evaluate anisotropic GGX direct reflection, then a second GGX coat lobe.
8. Optionally modulate the coat with thin-film interference at representative
   RGB wavelengths.
9. Add a bounded transmitted-light caustic, interaction illumination, adaptive
   tint, fine grain, and a directional bezel that selects light or dark
   contrast from the sampled environment instead of drawing a fixed border.
10. When interaction is enabled, advect the analytic normal with a bounded,
    smoothed velocity field. A trailing Gaussian wake bends refraction and
    drives a directional edge glint; `LiquidGlassGroup` shares that damped
    field with nearby surfaces without recapturing the backdrop.

The convex bevel uses an outward-facing normal, so transmission samples toward
the lens center at its rim. All texture samples are clamped to valid edge texel
centers. The initial refracted offset is capped by `maxDisplacement`; the edge
profile can scale it by up to 1.3. The tested capture envelope also includes
chromatic offsets, anisotropic scatter, reflection, and the capture texel size.
Every denominator has a non-zero lower bound to avoid NaNs and infinity at
grazing angles. See [REFERENCE_COMPARISON.md](REFERENCE_COMPARISON.md) for the
Flutter/web comparison behind the hardening changes.

## Parameters

| Layer | Parameters |
|---|---|
| Geometry | `thickness`, `curvature`, `edgeWidth`, `cornerSmoothing`, `maxDisplacement` |
| Transmission | `transmission`, `refractiveIndex`, `refractionStrength`, `roughness`, `blurSigma` |
| Volume | `absorptionColor`, `absorptionStrength`, `scatteringStrength` |
| Dispersion | `dispersionStrength`, `abbeNumber`, `chromaticAberration` (legacy artistic offset) |
| Base reflection | `fresnelStrength`, `specularStrength`, `environmentStrength` |
| Coat | `coatStrength`, `coatRoughness`, `coatRefractiveIndex` |
| Thin film | `thinFilmThickness`, `thinFilmRefractiveIndex`, `thinFilmStrength` |
| Directionality | `anisotropy`, `anisotropyRotation`, `lightDirection`, `lightColor`, `lightIntensity` |
| Motion | `motionStrength`; group `influenceRadius`, `motionGain`, `settleDuration` |
| Finishing | `causticStrength`, `innerShadow`, `tint`, `saturation`, `noise` |

## Limits

This remains a 2D UI material. It has one live backdrop image, one analytic
surface normal, and no scene depth, ray bounces, polarization, spectral power
distribution, or off-screen environment map. The physically motivated terms
make controls coherent and tunable; they do not turn a Flutter fragment effect
into an offline path tracer.
