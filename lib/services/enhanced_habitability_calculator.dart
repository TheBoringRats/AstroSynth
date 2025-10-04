import 'dart:math' as math;

import '../config/constants.dart';
import '../models/enhanced_habitability_result.dart';
import '../models/planet.dart';

/// Enhanced habitability calculator with 8 scientific factors
///
/// Based on peer-reviewed research:
/// - Magnetic field: Grießmeier et al. (2005) - radiation protection
/// - Plate tectonics: Valencia et al. (2007) - carbon cycle regulation
/// - Moon presence: Laskar et al. (1993) - axial tilt stabilization
/// - Orbital eccentricity: Williams & Pollard (2002) - climate stability
class EnhancedHabitabilityCalculator {
  static final EnhancedHabitabilityCalculator _instance =
      EnhancedHabitabilityCalculator._internal();
  factory EnhancedHabitabilityCalculator() => _instance;
  EnhancedHabitabilityCalculator._internal();

  /// Calculate complete enhanced habitability analysis
  EnhancedHabitabilityResult calculateHabitability(Planet planet) {
    // Calculate all 8 factors
    final tempScore = _calculateTemperatureScore(planet);
    final sizeScore = _calculateSizeScore(planet);
    final starScore = _calculateStarScore(planet);
    final orbitScore = _calculateOrbitScore(planet);
    final magneticScore = _calculateMagneticFieldScore(planet);
    final tectonicScore = _calculatePlateTectonicsScore(planet);
    final moonScore = _calculateMoonPresenceScore(planet);
    final eccentricityScore = _calculateEccentricityScore(planet);

    // Weighted average: 8 factors
    // Core habitability: 60% (temp 25%, size 15%, star 15%, orbit 5%)
    // Advanced factors: 40% (magnetic 10%, tectonics 10%, moon 10%, eccentricity 10%)
    final overallScore =
        (tempScore * 0.25 + // Temperature: most critical
        sizeScore * 0.15 + // Size: affects gravity, atmosphere retention
        starScore * 0.15 + // Star: radiation, stability
        orbitScore * 0.05 + // Orbit: habitable zone
        magneticScore * 0.10 + // Magnetic field: radiation protection
        tectonicScore * 0.10 + // Plate tectonics: carbon cycle
        moonScore * 0.10 + // Moon: tidal/axial stability
        eccentricityScore *
            0.10 // Eccentricity: climate stability
            );

    final strengths = _identifyStrengths(
      planet,
      tempScore,
      sizeScore,
      starScore,
      orbitScore,
      magneticScore,
      tectonicScore,
      moonScore,
      eccentricityScore,
    );

    final weaknesses = _identifyWeaknesses(
      planet,
      tempScore,
      sizeScore,
      starScore,
      orbitScore,
      magneticScore,
      tectonicScore,
      moonScore,
      eccentricityScore,
    );

    final recommendations = _generateRecommendations(planet, weaknesses);

    return EnhancedHabitabilityResult(
      temperatureScore: tempScore,
      sizeScore: sizeScore,
      starScore: starScore,
      orbitScore: orbitScore,
      magneticFieldScore: magneticScore,
      plateTectonicsScore: tectonicScore,
      moonPresenceScore: moonScore,
      eccentricityScore: eccentricityScore,
      overallScore: overallScore,
      temperatureAnalysis: _getTemperatureAnalysis(planet, tempScore),
      sizeAnalysis: _getSizeAnalysis(planet, sizeScore),
      starAnalysis: _getStarAnalysis(planet, starScore),
      orbitAnalysis: _getOrbitAnalysis(planet, orbitScore),
      magneticFieldAnalysis: _getMagneticFieldAnalysis(planet, magneticScore),
      plateTectonicsAnalysis: _getPlateTectonicsAnalysis(planet, tectonicScore),
      moonPresenceAnalysis: _getMoonPresenceAnalysis(planet, moonScore),
      eccentricityAnalysis: _getEccentricityAnalysis(planet, eccentricityScore),
      overallAnalysis: _getOverallAnalysis(overallScore),
      isHabitable: overallScore >= 50,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  // ============================================================
  // CORE 4 FACTORS (from original calculator)
  // ============================================================

  /// Calculate temperature habitability score (0-100)
  double _calculateTemperatureScore(Planet planet) {
    final temp = planet.equilibriumTemperature;
    if (temp == null) return 0.0;

    final optimalTemp = AppConstants.optimalHabitableTemp; // 288K (15°C)
    final minTemp = AppConstants.minHabitableTemp; // 273K (0°C)
    final maxTemp = AppConstants.maxHabitableTemp; // 323K (50°C)

    if (temp == optimalTemp) return 100.0;

    // Outside habitable zone
    if (temp < minTemp || temp > maxTemp) {
      if (temp < minTemp) {
        final diff = minTemp - temp;
        return math.max(0, 30 - (diff / 10));
      } else {
        final diff = temp - maxTemp;
        return math.max(0, 30 - (diff / 10));
      }
    }

    // Inside habitable zone
    final diff = (temp - optimalTemp).abs();
    final range = maxTemp - minTemp;
    final score = 100 - (diff / range * 70);
    return math.max(0, math.min(100, score));
  }

  /// Calculate size habitability score (0-100)
  double _calculateSizeScore(Planet planet) {
    final radius = planet.radius;
    if (radius == null) return 50.0; // Neutral score if unknown

    // Optimal range: 0.8 - 1.5 Earth radii
    // Super-Earths (1.5-2.5) can be habitable but less ideal
    // Mini-Neptunes (>2.5) likely gas giants
    if (radius >= 0.8 && radius <= 1.5) {
      return 100.0 - ((radius - 1.0).abs() * 30); // Penalty from Earth size
    }

    if (radius < 0.8) {
      // Too small: weak gravity, can't retain atmosphere
      return math.max(0, 70 - ((0.8 - radius) * 100));
    }

    if (radius <= 2.5) {
      // Super-Earth: possible but challenging
      return math.max(20, 70 - ((radius - 1.5) * 40));
    }

    // Too large: likely gas giant
    return math.max(0, 20 - ((radius - 2.5) * 10));
  }

  /// Calculate star type habitability score (0-100)
  double _calculateStarScore(Planet planet) {
    final starType = planet.stellarSpectralType?.toUpperCase();
    if (starType == null) return 50.0;

    // G-type (Sun-like): optimal (100)
    // K-type (orange dwarf): excellent (95) - longer lifespan
    // F-type (yellow-white): good (85) - shorter lifespan
    // M-type (red dwarf): moderate (60) - flares, tidal locking
    // A, B, O-type: poor (<30) - too hot, short-lived
    if (starType.startsWith('G')) return 100.0;
    if (starType.startsWith('K')) return 95.0;
    if (starType.startsWith('F')) return 85.0;
    if (starType.startsWith('M')) return 60.0;
    if (starType.startsWith('A')) return 30.0;
    if (starType.startsWith('B') || starType.startsWith('O')) return 10.0;

    return 50.0; // Unknown type
  }

  /// Calculate orbit habitability score (0-100)
  double _calculateOrbitScore(Planet planet) {
    final period = planet.orbitalPeriod;
    if (period == null) return 50.0;

    // Optimal: 200-500 days (Earth-like seasons)
    // Too short (<50 days): close to star, hot
    // Too long (>1000 days): far from star, cold
    if (period >= 200 && period <= 500) {
      return 100.0;
    }

    if (period >= 100 && period < 200) {
      return 80.0 + ((period - 100) / 100 * 20);
    }

    if (period > 500 && period <= 1000) {
      return 80.0 - ((period - 500) / 500 * 30);
    }

    if (period < 100) {
      return math.max(0, 50 - ((100 - period) / 2));
    }

    // Very long period
    return math.max(0, 50 - ((period - 1000) / 100));
  }

  // ============================================================
  // NEW 4 FACTORS
  // ============================================================

  /// Calculate magnetic field score (0-100)
  /// Based on mass and rotation rate
  /// Reference: Grießmeier et al. (2005) - Cosmic radiation shielding
  double _calculateMagneticFieldScore(Planet planet) {
    final mass = planet.mass;
    final radius = planet.radius;

    // If we don't have data, assume moderate field (50)
    if (mass == null || radius == null) return 50.0;

    // Magnetic field strength proportional to:
    // 1. Core size (larger planet = larger core)
    // 2. Rotation rate (faster = stronger dynamo)
    // 3. Internal heat (younger = more active)

    // Estimate field strength from mass/radius ratio (density proxy)
    final density = mass / (radius * radius * radius);

    // Earth density: ~5.5 g/cm³
    // High density (rocky) = iron core = strong field
    double fieldStrength;
    if (density >= 0.8 && density <= 1.2) {
      // Earth-like density
      fieldStrength = 90.0 + (math.Random().nextDouble() * 10); // 90-100
    } else if (density >= 0.5 && density < 0.8) {
      // Lower density (Mars-like)
      fieldStrength = 40.0 + ((density - 0.5) / 0.3 * 50);
    } else if (density > 1.2 && density <= 1.5) {
      // Higher density (Mercury-like)
      fieldStrength = 70.0 + ((1.5 - density) / 0.3 * 20);
    } else if (density < 0.5) {
      // Very low density (weak field)
      fieldStrength = 20.0;
    } else {
      // Very high density (super-Earth)
      fieldStrength = 60.0;
    }

    // Size factor: larger planets have stronger fields
    if (radius > 1.5) {
      fieldStrength = math.min(100, fieldStrength * 1.1);
    } else if (radius < 0.8) {
      fieldStrength *= 0.8;
    }

    return math.max(0, math.min(100, fieldStrength));
  }

  /// Calculate plate tectonics probability (0-100)
  /// Based on size, age, and composition
  /// Reference: Valencia et al. (2007) - Super-Earth geophysics
  double _calculatePlateTectonicsScore(Planet planet) {
    final radius = planet.radius;
    final mass = planet.mass;

    if (radius == null || mass == null) return 50.0;

    // Plate tectonics requires:
    // 1. Right size (0.5-2.0 Earth radii)
    // 2. Rocky composition (not gas giant)
    // 3. Internal heat (drives mantle convection)
    // 4. Water (lubricates subduction)

    // Size factor
    double tectonicScore;
    if (radius >= 0.8 && radius <= 1.5) {
      // Earth-like size: optimal for plate tectonics
      tectonicScore = 95.0;
    } else if (radius >= 0.5 && radius < 0.8) {
      // Smaller (Mars-like): cools faster, less active
      tectonicScore = 40.0 + ((radius - 0.5) / 0.3 * 55);
    } else if (radius > 1.5 && radius <= 2.0) {
      // Super-Earth: might have stagnant lid (too thick crust)
      tectonicScore = 70.0 - ((radius - 1.5) / 0.5 * 30);
    } else if (radius > 2.0) {
      // Too large: likely stagnant lid or gas giant
      tectonicScore = math.max(10, 40 - ((radius - 2.0) * 20));
    } else {
      // Too small (< 0.5): insufficient internal heat
      tectonicScore = 20.0;
    }

    // Mass-radius relationship (composition check)
    final density = mass / (radius * radius * radius);
    if (density < 0.4) {
      // Too low density: likely icy or gaseous
      tectonicScore *= 0.5;
    }

    return math.max(0, math.min(100, tectonicScore));
  }

  /// Calculate moon presence score (0-100)
  /// Based on probability of having a stabilizing moon
  /// Reference: Laskar et al. (1993) - Axial tilt stabilization
  double _calculateMoonPresenceScore(Planet planet) {
    final mass = planet.mass;
    final radius = planet.radius;

    if (mass == null || radius == null) return 50.0;

    // Moon benefits:
    // 1. Stabilizes axial tilt (prevents extreme seasons)
    // 2. Creates tides (mix oceans, tidal pools for early life)
    // 3. Slows rotation (longer days)

    // Probability of having a large moon increases with:
    // - Planet mass (larger planets can capture/retain moons)
    // - Distance from star (moons in close orbits get stripped)

    double moonProbability;

    if (mass >= 0.5 && mass <= 2.0) {
      // Earth-like mass: good chance of large moon
      moonProbability = 70.0 + (math.Random().nextDouble() * 20); // 70-90
    } else if (mass < 0.5) {
      // Small planet: harder to capture/retain large moon
      moonProbability = 30.0 + (mass / 0.5 * 40);
    } else {
      // Super-Earth: very likely to have moons
      moonProbability = 80.0 + math.min(20, (mass - 2.0) * 10);
    }

    // Assume some randomness (we don't have real moon data)
    return math.max(0, math.min(100, moonProbability));
  }

  /// Calculate orbital eccentricity score (0-100)
  /// Lower eccentricity = more stable climate
  /// Reference: Williams & Pollard (2002) - Climate stability
  double _calculateEccentricityScore(Planet planet) {
    final eccentricity = planet.eccentricity;

    if (eccentricity == null) return 70.0; // Assume moderate if unknown

    // Eccentricity scale:
    // 0.0 = perfect circle (best)
    // 0.017 = Earth (excellent)
    // 0.0934 = Mars (acceptable)
    // 0.206 = Mercury (challenging)
    // >0.3 = extreme seasons, less habitable

    if (eccentricity <= 0.05) {
      // Nearly circular: excellent climate stability
      return 100.0 - (eccentricity * 200); // 100 at e=0, 90 at e=0.05
    } else if (eccentricity <= 0.15) {
      // Low eccentricity: good stability
      return 90.0 - ((eccentricity - 0.05) * 400); // 90 to 50
    } else if (eccentricity <= 0.3) {
      // Moderate eccentricity: challenging but possible
      return 50.0 - ((eccentricity - 0.15) * 200); // 50 to 20
    } else {
      // High eccentricity: extreme climate swings
      return math.max(0, 20 - ((eccentricity - 0.3) * 50));
    }
  }

  // ============================================================
  // ANALYSIS TEXT GENERATION
  // ============================================================

  String _getTemperatureAnalysis(Planet planet, double score) {
    final temp = planet.equilibriumTemperature;
    if (temp == null) return 'Temperature data unavailable';

    final celsius = temp - 273.15;
    if (score >= 80) {
      return 'Excellent temperature (${celsius.toStringAsFixed(1)}°C) - ideal for liquid water';
    } else if (score >= 60) {
      return 'Good temperature (${celsius.toStringAsFixed(1)}°C) - water can exist';
    } else if (score >= 40) {
      return 'Marginal temperature (${celsius.toStringAsFixed(1)}°C) - challenging conditions';
    } else {
      return 'Poor temperature (${celsius.toStringAsFixed(1)}°C) - too ${temp < 273 ? 'cold' : 'hot'}';
    }
  }

  String _getSizeAnalysis(Planet planet, double score) {
    final radius = planet.radius;
    if (radius == null) return 'Size data unavailable';

    if (score >= 80) {
      return 'Earth-like size (${radius.toStringAsFixed(2)} R⊕) - ideal for retaining atmosphere';
    } else if (score >= 60) {
      return 'Good size (${radius.toStringAsFixed(2)} R⊕) - can retain substantial atmosphere';
    } else if (score >= 40) {
      return 'Marginal size (${radius.toStringAsFixed(2)} R⊕) - may struggle with atmosphere retention';
    } else {
      return 'Poor size (${radius.toStringAsFixed(2)} R⊕) - ${radius < 0.5 ? 'too small' : 'likely gas giant'}';
    }
  }

  String _getStarAnalysis(Planet planet, double score) {
    final starType = planet.stellarSpectralType ?? 'Unknown';
    if (score >= 90) {
      return 'Excellent star type ($starType) - Sun-like or better';
    } else if (score >= 70) {
      return 'Good star type ($starType) - suitable for life';
    } else if (score >= 50) {
      return 'Marginal star type ($starType) - potential challenges';
    } else {
      return 'Poor star type ($starType) - unstable or short-lived';
    }
  }

  String _getOrbitAnalysis(Planet planet, double score) {
    final period = planet.orbitalPeriod;
    if (period == null) return 'Orbital data unavailable';

    final years = period / 365.25;
    if (score >= 80) {
      return 'Excellent orbit (${years.toStringAsFixed(2)} years) - Earth-like seasons';
    } else if (score >= 60) {
      return 'Good orbit (${years.toStringAsFixed(2)} years) - stable climate possible';
    } else {
      return 'Marginal orbit (${years.toStringAsFixed(2)} years) - ${years < 0.3 ? 'too close' : 'too far'}';
    }
  }

  String _getMagneticFieldAnalysis(Planet planet, double score) {
    if (score >= 80) {
      return 'Strong magnetic field - excellent radiation protection';
    } else if (score >= 60) {
      return 'Moderate magnetic field - good cosmic ray shielding';
    } else if (score >= 40) {
      return 'Weak magnetic field - limited radiation protection';
    } else {
      return 'No/minimal magnetic field - vulnerable to solar wind';
    }
  }

  String _getPlateTectonicsAnalysis(Planet planet, double score) {
    if (score >= 80) {
      return 'Active plate tectonics likely - regulates carbon cycle';
    } else if (score >= 60) {
      return 'Possible plate tectonics - carbon cycle may function';
    } else if (score >= 40) {
      return 'Limited tectonic activity - reduced carbon recycling';
    } else {
      return 'Stagnant lid likely - no plate tectonics or carbon cycle';
    }
  }

  String _getMoonPresenceAnalysis(Planet planet, double score) {
    if (score >= 70) {
      return 'Large moon likely - stabilizes axial tilt and creates tides';
    } else if (score >= 50) {
      return 'Moon possible - may provide some stability';
    } else {
      return 'No large moon likely - unstable axial tilt over time';
    }
  }

  String _getEccentricityAnalysis(Planet planet, double score) {
    final ecc = planet.eccentricity;
    if (ecc == null) return 'Orbital shape unknown';

    if (score >= 90) {
      return 'Nearly circular orbit (e=${ecc.toStringAsFixed(3)}) - very stable climate';
    } else if (score >= 70) {
      return 'Low eccentricity (e=${ecc.toStringAsFixed(3)}) - stable seasons';
    } else if (score >= 40) {
      return 'Moderate eccentricity (e=${ecc.toStringAsFixed(3)}) - variable climate';
    } else {
      return 'High eccentricity (e=${ecc.toStringAsFixed(3)}) - extreme seasonal swings';
    }
  }

  String _getOverallAnalysis(double score) {
    if (score >= 75) {
      return 'Exceptional habitability across all factors. Prime candidate for life.';
    } else if (score >= 60) {
      return 'Very habitable with strong fundamentals. Excellent prospects for life.';
    } else if (score >= 45) {
      return 'Potentially habitable with some challenges. Life may adapt.';
    } else if (score >= 30) {
      return 'Marginally habitable. Significant obstacles for complex life.';
    } else {
      return 'Unlikely habitable. Multiple critical factors unfavorable.';
    }
  }

  // ============================================================
  // STRENGTHS, WEAKNESSES, RECOMMENDATIONS
  // ============================================================

  List<String> _identifyStrengths(
    Planet planet,
    double tempScore,
    double sizeScore,
    double starScore,
    double orbitScore,
    double magneticScore,
    double tectonicScore,
    double moonScore,
    double eccentricityScore,
  ) {
    final strengths = <String>[];

    if (tempScore >= 80) strengths.add('Ideal temperature range');
    if (sizeScore >= 80) strengths.add('Earth-like size');
    if (starScore >= 90) strengths.add('Sun-like host star');
    if (orbitScore >= 80) strengths.add('Stable orbital period');
    if (magneticScore >= 80) strengths.add('Strong radiation shield');
    if (tectonicScore >= 80) strengths.add('Active geology');
    if (moonScore >= 70) strengths.add('Stabilizing moon likely');
    if (eccentricityScore >= 90) strengths.add('Circular orbit');

    if (strengths.isEmpty) {
      strengths.add('Some basic habitability factors present');
    }

    return strengths;
  }

  List<String> _identifyWeaknesses(
    Planet planet,
    double tempScore,
    double sizeScore,
    double starScore,
    double orbitScore,
    double magneticScore,
    double tectonicScore,
    double moonScore,
    double eccentricityScore,
  ) {
    final weaknesses = <String>[];

    if (tempScore < 40) weaknesses.add('Temperature outside habitable zone');
    if (sizeScore < 40) weaknesses.add('Size unfavorable for atmosphere');
    if (starScore < 50) weaknesses.add('Star type presents challenges');
    if (orbitScore < 40) weaknesses.add('Orbital distance suboptimal');
    if (magneticScore < 40) weaknesses.add('Weak magnetic protection');
    if (tectonicScore < 40) weaknesses.add('Limited geological activity');
    if (moonScore < 40) weaknesses.add('No stabilizing moon');
    if (eccentricityScore < 40)
      weaknesses.add('Elliptical orbit causes climate swings');

    if (weaknesses.isEmpty) {
      weaknesses.add('All factors within acceptable ranges');
    }

    return weaknesses;
  }

  List<String> _generateRecommendations(
    Planet planet,
    List<String> weaknesses,
  ) {
    final recommendations = <String>[];

    if (weaknesses.contains('Temperature outside habitable zone')) {
      recommendations.add(
        'Search for alternative biochemistries adapted to extreme temps',
      );
    }
    if (weaknesses.contains('Weak magnetic protection')) {
      recommendations.add('Consider subsurface life protected from radiation');
    }
    if (weaknesses.contains('Limited geological activity')) {
      recommendations.add('Look for alternative nutrient cycling mechanisms');
    }
    if (weaknesses.contains('Elliptical orbit causes climate swings')) {
      recommendations.add('Life may exist but require extreme adaptability');
    }

    // Check if in habitable zone based on temperature
    if (planet.equilibriumTemperature != null &&
        planet.equilibriumTemperature! >= 273 &&
        planet.equilibriumTemperature! <= 323) {
      recommendations.add('Priority target for follow-up observations');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Excellent candidate for detailed study');
    }

    return recommendations;
  }
}
