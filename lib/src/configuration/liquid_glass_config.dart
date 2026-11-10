import 'package:flutter/material.dart';

/// Rendering cost and optical fidelity of a [LiquidGlassConfig].
enum LiquidGlassQuality { performance, balanced, ultra }

/// Selects how a liquid glass surface chooses its renderer.
enum LiquidGlassRenderer { auto, capture, shader, fallback }

/// The concrete renderer selected for a [LiquidGlassConfig].
enum LiquidGlassRenderPath { capture, filter, fallback }

/// Immutable optical and performance settings for a glass surface.
@immutable
class LiquidGlassConfig {
  /// Creates a balanced, broadly useful glass material.
  const LiquidGlassConfig({
    this.blurSigma = 5.5,
    this.refractionStrength = 0.052,
    this.fresnelStrength = 0.72,
    this.specularStrength = 0.62,
    this.chromaticAberration = 0.00015,
    this.roughness = 0.22,
    this.transmission = 0.94,
    this.thickness = 0.78,
    this.absorptionColor = const Color(0xFFF2FAFF),
    this.absorptionStrength = 0.25,
    this.scatteringStrength = 0.08,
    this.dispersionStrength = 0.12,
    this.abbeNumber = 55,
    this.environmentStrength = 0.55,
    this.coatStrength = 0.22,
    this.coatRoughness = 0.12,
    this.coatRefractiveIndex = 1.46,
    this.thinFilmThickness = 0,
    this.thinFilmRefractiveIndex = 1.33,
    this.thinFilmStrength = 0,
    this.anisotropy = 0.10,
    this.anisotropyRotation = 0.125,
    this.causticStrength = 0.40,
    this.curvature = 0.9,
    this.refractiveIndex = 1.46,
    this.cornerSmoothing = 0.72,
    this.innerShadow = 0.18,
    this.edgeWidth = 0.065,
    this.maxDisplacement = 20,
    this.saturation = 1.04,
    this.vibrancy = 0,
    this.tint = const Color(0x10FFFFFF),
    this.lightDirection = const Offset(-0.65, -0.75),
    this.lightColor = Colors.white,
    this.lightIntensity = 1,
    this.motionStrength = 0.85,
    this.noise = 0.002,
    this.borderWidth = 0,
    this.quality = LiquidGlassQuality.balanced,
    this.renderer = LiquidGlassRenderer.auto,
    this.animateLight = false,
    this.animationDuration = const Duration(seconds: 8),
  })  : assert(blurSigma >= 0 && blurSigma <= 30),
        assert(refractionStrength >= 0 && refractionStrength <= 0.12),
        assert(fresnelStrength >= 0 && fresnelStrength <= 2),
        assert(specularStrength >= 0 && specularStrength <= 2),
        assert(chromaticAberration >= 0 && chromaticAberration <= 0.01),
        assert(roughness >= 0 && roughness <= 1),
        assert(transmission >= 0 && transmission <= 1),
        assert(thickness >= 0 && thickness <= 2),
        assert(absorptionStrength >= 0 && absorptionStrength <= 8),
        assert(scatteringStrength >= 0 && scatteringStrength <= 1),
        assert(dispersionStrength >= 0 && dispersionStrength <= 2),
        assert(abbeNumber >= 5 && abbeNumber <= 200),
        assert(environmentStrength >= 0 && environmentStrength <= 2),
        assert(coatStrength >= 0 && coatStrength <= 1),
        assert(coatRoughness >= 0 && coatRoughness <= 1),
        assert(coatRefractiveIndex >= 1 && coatRefractiveIndex <= 3),
        assert(thinFilmThickness >= 0 && thinFilmThickness <= 2000),
        assert(
          thinFilmRefractiveIndex >= 1 && thinFilmRefractiveIndex <= 3,
        ),
        assert(thinFilmStrength >= 0 && thinFilmStrength <= 1),
        assert(anisotropy >= -0.95 && anisotropy <= 0.95),
        assert(anisotropyRotation >= 0 && anisotropyRotation <= 1),
        assert(causticStrength >= 0 && causticStrength <= 2),
        assert(curvature >= 0 && curvature <= 2),
        assert(refractiveIndex >= 1 && refractiveIndex <= 2),
        assert(cornerSmoothing >= 0 && cornerSmoothing <= 1),
        assert(innerShadow >= 0 && innerShadow <= 1),
        assert(edgeWidth > 0 && edgeWidth <= 0.5),
        assert(maxDisplacement >= 0 && maxDisplacement <= 64),
        assert(saturation >= 0 && saturation <= 2),
        assert(vibrancy >= 0 && vibrancy <= 1),
        assert(lightIntensity >= 0 && lightIntensity <= 10),
        assert(motionStrength >= 0 && motionStrength <= 3),
        assert(noise >= 0 && noise <= 0.1),
        assert(borderWidth >= 0 && borderWidth <= 8);

  /// Adaptive glass for navigation, toolbars, and floating controls.
  const LiquidGlassConfig.regular() : this();

  /// Highly transparent glass for visually rich backdrops.
  const LiquidGlassConfig.clear()
      : this(
          blurSigma: 1.5,
          refractionStrength: 0.072,
          fresnelStrength: 0.9,
          specularStrength: 0.85,
          chromaticAberration: 0.0002,
          roughness: 0.045,
          transmission: 0.985,
          thickness: 0.95,
          absorptionColor: Colors.white,
          absorptionStrength: 0,
          scatteringStrength: 0.02,
          dispersionStrength: 0.28,
          abbeNumber: 52,
          environmentStrength: 0.72,
          coatStrength: 0.42,
          coatRoughness: 0.055,
          thinFilmThickness: 420,
          thinFilmStrength: 0.025,
          anisotropy: 0.14,
          causticStrength: 0.72,
          motionStrength: 1.1,
          curvature: 1.05,
          cornerSmoothing: 0.78,
          innerShadow: 0.12,
          edgeWidth: 0.055,
          maxDisplacement: 24,
          saturation: 1.08,
          tint: const Color(0x08FFFFFF),
          noise: 0.001,
          quality: LiquidGlassQuality.ultra,
        );

  /// Clear, refractive glass for prominent floating controls.
  const LiquidGlassConfig.crystal() : this.clear();

  /// Softer, more legible glass for content-heavy surfaces.
  const LiquidGlassConfig.frosted()
      : this(
          blurSigma: 11,
          refractionStrength: 0.032,
          fresnelStrength: 0.55,
          specularStrength: 0.42,
          chromaticAberration: 0,
          roughness: 0.55,
          transmission: 0.84,
          thickness: 0.68,
          absorptionColor: const Color(0xFFF5F8FF),
          absorptionStrength: 0.36,
          scatteringStrength: 0.38,
          dispersionStrength: 0,
          environmentStrength: 0.32,
          coatStrength: 0.12,
          coatRoughness: 0.32,
          causticStrength: 0.18,
          motionStrength: 0.52,
          curvature: 0.85,
          innerShadow: 0.22,
          edgeWidth: 0.07,
          maxDisplacement: 16,
          saturation: 0.96,
          tint: const Color(0x20FFFFFF),
          noise: 0.003,
        );

  /// Low-cost material for dense layouts and constrained devices.
  const LiquidGlassConfig.performance()
      : this(
          blurSigma: 3,
          refractionStrength: 0.035,
          fresnelStrength: 0.5,
          specularStrength: 0.38,
          chromaticAberration: 0,
          roughness: 0.16,
          transmission: 0.92,
          thickness: 0.65,
          absorptionStrength: 0.16,
          scatteringStrength: 0.05,
          dispersionStrength: 0,
          environmentStrength: 0.38,
          coatStrength: 0.12,
          coatRoughness: 0.18,
          causticStrength: 0.24,
          motionStrength: 0.45,
          innerShadow: 0.14,
          edgeWidth: 0.06,
          maxDisplacement: 12,
          saturation: 1,
          tint: const Color(0x12FFFFFF),
          noise: 0,
          quality: LiquidGlassQuality.performance,
        );

  final double blurSigma;
  final double refractionStrength;
  final double fresnelStrength;
  final double specularStrength;
  final double chromaticAberration;
  final double roughness;
  final double transmission;
  final double thickness;
  final Color absorptionColor;
  final double absorptionStrength;
  final double scatteringStrength;
  final double dispersionStrength;
  final double abbeNumber;
  final double environmentStrength;
  final double coatStrength;
  final double coatRoughness;
  final double coatRefractiveIndex;
  final double thinFilmThickness;
  final double thinFilmRefractiveIndex;
  final double thinFilmStrength;
  final double anisotropy;
  final double anisotropyRotation;
  final double causticStrength;
  final double curvature;
  final double refractiveIndex;
  final double cornerSmoothing;
  final double innerShadow;
  final double edgeWidth;
  final double maxDisplacement;
  final double saturation;

  /// Boosts muted midtone chroma while preserving neutrals and primary colors.
  final double vibrancy;
  final Color tint;
  final Offset lightDirection;
  final Color lightColor;
  final double lightIntensity;

  /// Strength of velocity-driven normal deformation and moving highlights.
  final double motionStrength;

  final double noise;
  final double borderWidth;
  final LiquidGlassQuality quality;
  final LiquidGlassRenderer renderer;
  final bool animateLight;
  final Duration animationDuration;

  /// Returns a copy with selected values replaced.
  LiquidGlassConfig copyWith({
    double? blurSigma,
    double? refractionStrength,
    double? fresnelStrength,
    double? specularStrength,
    double? chromaticAberration,
    double? roughness,
    double? transmission,
    double? thickness,
    Color? absorptionColor,
    double? absorptionStrength,
    double? scatteringStrength,
    double? dispersionStrength,
    double? abbeNumber,
    double? environmentStrength,
    double? coatStrength,
    double? coatRoughness,
    double? coatRefractiveIndex,
    double? thinFilmThickness,
    double? thinFilmRefractiveIndex,
    double? thinFilmStrength,
    double? anisotropy,
    double? anisotropyRotation,
    double? causticStrength,
    double? curvature,
    double? refractiveIndex,
    double? cornerSmoothing,
    double? innerShadow,
    double? edgeWidth,
    double? maxDisplacement,
    double? saturation,
    double? vibrancy,
    Color? tint,
    Offset? lightDirection,
    Color? lightColor,
    double? lightIntensity,
    double? motionStrength,
    double? noise,
    double? borderWidth,
    LiquidGlassQuality? quality,
    LiquidGlassRenderer? renderer,
    bool? animateLight,
    Duration? animationDuration,
  }) =>
      LiquidGlassConfig(
        blurSigma: blurSigma ?? this.blurSigma,
        refractionStrength: refractionStrength ?? this.refractionStrength,
        fresnelStrength: fresnelStrength ?? this.fresnelStrength,
        specularStrength: specularStrength ?? this.specularStrength,
        chromaticAberration: chromaticAberration ?? this.chromaticAberration,
        roughness: roughness ?? this.roughness,
        transmission: transmission ?? this.transmission,
        thickness: thickness ?? this.thickness,
        absorptionColor: absorptionColor ?? this.absorptionColor,
        absorptionStrength: absorptionStrength ?? this.absorptionStrength,
        scatteringStrength: scatteringStrength ?? this.scatteringStrength,
        dispersionStrength: dispersionStrength ?? this.dispersionStrength,
        abbeNumber: abbeNumber ?? this.abbeNumber,
        environmentStrength: environmentStrength ?? this.environmentStrength,
        coatStrength: coatStrength ?? this.coatStrength,
        coatRoughness: coatRoughness ?? this.coatRoughness,
        coatRefractiveIndex: coatRefractiveIndex ?? this.coatRefractiveIndex,
        thinFilmThickness: thinFilmThickness ?? this.thinFilmThickness,
        thinFilmRefractiveIndex:
            thinFilmRefractiveIndex ?? this.thinFilmRefractiveIndex,
        thinFilmStrength: thinFilmStrength ?? this.thinFilmStrength,
        anisotropy: anisotropy ?? this.anisotropy,
        anisotropyRotation: anisotropyRotation ?? this.anisotropyRotation,
        causticStrength: causticStrength ?? this.causticStrength,
        curvature: curvature ?? this.curvature,
        refractiveIndex: refractiveIndex ?? this.refractiveIndex,
        cornerSmoothing: cornerSmoothing ?? this.cornerSmoothing,
        innerShadow: innerShadow ?? this.innerShadow,
        edgeWidth: edgeWidth ?? this.edgeWidth,
        maxDisplacement: maxDisplacement ?? this.maxDisplacement,
        saturation: saturation ?? this.saturation,
        vibrancy: vibrancy ?? this.vibrancy,
        tint: tint ?? this.tint,
        lightDirection: lightDirection ?? this.lightDirection,
        lightColor: lightColor ?? this.lightColor,
        lightIntensity: lightIntensity ?? this.lightIntensity,
        motionStrength: motionStrength ?? this.motionStrength,
        noise: noise ?? this.noise,
        borderWidth: borderWidth ?? this.borderWidth,
        quality: quality ?? this.quality,
        renderer: renderer ?? this.renderer,
        animateLight: animateLight ?? this.animateLight,
        animationDuration: animationDuration ?? this.animationDuration,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassConfig &&
          blurSigma == other.blurSigma &&
          refractionStrength == other.refractionStrength &&
          fresnelStrength == other.fresnelStrength &&
          specularStrength == other.specularStrength &&
          chromaticAberration == other.chromaticAberration &&
          roughness == other.roughness &&
          transmission == other.transmission &&
          thickness == other.thickness &&
          absorptionColor == other.absorptionColor &&
          absorptionStrength == other.absorptionStrength &&
          scatteringStrength == other.scatteringStrength &&
          dispersionStrength == other.dispersionStrength &&
          abbeNumber == other.abbeNumber &&
          environmentStrength == other.environmentStrength &&
          coatStrength == other.coatStrength &&
          coatRoughness == other.coatRoughness &&
          coatRefractiveIndex == other.coatRefractiveIndex &&
          thinFilmThickness == other.thinFilmThickness &&
          thinFilmRefractiveIndex == other.thinFilmRefractiveIndex &&
          thinFilmStrength == other.thinFilmStrength &&
          anisotropy == other.anisotropy &&
          anisotropyRotation == other.anisotropyRotation &&
          causticStrength == other.causticStrength &&
          curvature == other.curvature &&
          refractiveIndex == other.refractiveIndex &&
          cornerSmoothing == other.cornerSmoothing &&
          innerShadow == other.innerShadow &&
          edgeWidth == other.edgeWidth &&
          maxDisplacement == other.maxDisplacement &&
          saturation == other.saturation &&
          vibrancy == other.vibrancy &&
          tint == other.tint &&
          lightDirection == other.lightDirection &&
          lightColor == other.lightColor &&
          lightIntensity == other.lightIntensity &&
          motionStrength == other.motionStrength &&
          noise == other.noise &&
          borderWidth == other.borderWidth &&
          quality == other.quality &&
          renderer == other.renderer &&
          animateLight == other.animateLight &&
          animationDuration == other.animationDuration;

  @override
  int get hashCode => Object.hashAll(<Object>[
        blurSigma,
        refractionStrength,
        fresnelStrength,
        specularStrength,
        chromaticAberration,
        roughness,
        transmission,
        thickness,
        absorptionColor,
        absorptionStrength,
        scatteringStrength,
        dispersionStrength,
        abbeNumber,
        environmentStrength,
        coatStrength,
        coatRoughness,
        coatRefractiveIndex,
        thinFilmThickness,
        thinFilmRefractiveIndex,
        thinFilmStrength,
        anisotropy,
        anisotropyRotation,
        causticStrength,
        curvature,
        refractiveIndex,
        cornerSmoothing,
        innerShadow,
        edgeWidth,
        maxDisplacement,
        saturation,
        vibrancy,
        tint,
        lightDirection,
        lightColor,
        lightIntensity,
        motionStrength,
        noise,
        borderWidth,
        quality,
        renderer,
        animateLight,
        animationDuration,
      ]);
}
