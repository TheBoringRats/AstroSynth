import 'dart:math' as math;

import '../config/constants.dart';
import '../models/habitability_result.dart';
import '../models/planet.dart';

/// Service for calculating habitability scores of exoplanets
class HabitabilityCalculator {
  static final HabitabilityCalculator _instance =
      HabitabilityCalculator._internal();
  factory HabitabilityCalculator() => _instance;
  HabitabilityCalculator._internal();

  /// Calculate complete habitability analysis for a planet
  HabitabilityResult calculateHabitability(Planet planet) {
    final tempScore = _calculateTemperatureScore(planet);
    final sizeScore = _calculateSizeScore(planet);
    final starScore = _calculateStarScore(planet);
    final orbitScore = _calculateOrbitScore(planet);

    // Weighted average: Temperature and star are most important
    final overallScore =
        (tempScore * 0.35 + // 35% weight
        sizeScore * 0.20 + // 20% weight
        starScore * 0.30 + // 30% weight
        orbitScore *
            0.15 // 15% weight
            );

    final strengths = _identifyStrengths(
      planet,
      tempScore,
      sizeScore,
      starScore,
      orbitScore,
    );
    final weaknesses = _identifyWeaknesses(
      planet,
      tempScore,
      sizeScore,
      starScore,
      orbitScore,
    );
    final recommendations = _generateRecommendations(planet, weaknesses);

    return HabitabilityResult(
      temperatureScore: tempScore,
      sizeScore: sizeScore,
      starScore: starScore,
      orbitScore: orbitScore,
      overallScore: overallScore,
      temperatureAnalysis: _getTemperatureAnalysis(planet, tempScore),
      sizeAnalysis: _getSizeAnalysis(planet, sizeScore),
      starAnalysis: _getStarAnalysis(planet, starScore),
      orbitAnalysis: _getOrbitAnalysis(planet, orbitScore),
      overallAnalysis: _getOverallAnalysis(overallScore),
      isHabitable: overallScore >= 50,
      strengths: strengths,
      weaknesses: weaknesses,
      recommendations: recommendations,
    );
  }

  /// Calculate temperature habitability score (0-100)
  double _calculateTemperatureScore(Planet planet) {
    final temp = planet.equilibriumTemperature;

    if (temp == null) return 0.0;

    final optimalTemp = AppConstants.optimalHabitableTemp;
    final minTemp = AppConstants.minHabitableTemp;
    final maxTemp = AppConstants.maxHabitableTemp;

    // Perfect score at optimal temperature (288K / 15°C)
    if (temp == optimalTemp) return 100.0;

    // Outside habitable zone
    if (temp < minTemp || temp > maxTemp) {
      // Calculate how far outside the zone
      if (temp < minTemp) {
        final diff = minTemp - temp;
        return math.max(
          0,
          30 - (diff / 10),
        ); // Decrease score based on coldness
      } else {
        final diff = temp - maxTemp;
        return math.max(0, 30 - (diff / 10)); // Decrease score based on heat
      }
    }

    // Inside habitable zone - calculate based on distance from optimal
    final diff = (temp - optimalTemp).abs();
    final range = maxTemp - minTemp;
    final score = 100 - (diff / range * 70); // Max penalty of 70 points

    return math.max(0, math.min(100, score));
  }

  /// Calculate size habitability score (0-100)
  double _calculateSizeScore(Planet planet) {
    final radius = planet.radius;

    if (radius == null) return 0.0;

    final minRadius = AppConstants.minHabitableRadius;
    final maxRadius = AppConstants.maxHabitableRadius;

    // Optimal size: 0.8 - 1.5 Earth radii
    if (radius >= 0.8 && radius <= 1.5) {
      return 100.0;
    }

    // Too small
    if (radius < minRadius) {
      return math.max(0, 40 - ((minRadius - radius) * 30));
    }

    // Too large
    if (radius > maxRadius) {
      return math.max(0, 60 - ((radius - maxRadius) * 20));
    }

    // Within habitable range but not optimal
    if (radius < 0.8) {
      final diff = 0.8 - radius;
      return 100 - (diff / 0.3 * 30); // Penalty for being smaller
    } else {
      final diff = radius - 1.5;
      return 100 - (diff / 1.0 * 30); // Penalty for being larger
    }
  }

  /// Calculate star type habitability score (0-100)
  double _calculateStarScore(Planet planet) {
    final starType = planet.stellarSpectralType;

    if (starType == null || starType.isEmpty) return 0.0;

    // Get first character (main spectral class)
    final mainClass = starType[0].toUpperCase();

    // Score based on spectral class
    switch (mainClass) {
      case 'G': // Sun-like stars - optimal
        return 100.0;
      case 'K': // Orange dwarfs - good
        return 90.0;
      case 'F': // Yellow-white stars - good
        return 85.0;
      case 'M': // Red dwarfs - potentially habitable but with issues
        return 70.0;
      case 'A': // White stars - too hot
        return 40.0;
      case 'B': // Blue-white stars - too hot and short-lived
        return 20.0;
      case 'O': // Blue stars - too hot and very short-lived
        return 10.0;
      default:
        return 30.0;
    }
  }

  /// Calculate orbital characteristics score (0-100)
  double _calculateOrbitScore(Planet planet) {
    double score = 100.0;

    // Check eccentricity (circular orbits are better)
    final eccentricity = planet.eccentricity;
    if (eccentricity != null) {
      if (eccentricity > 0.3) {
        score -= 30; // High eccentricity penalized
      } else if (eccentricity > 0.1) {
        score -= (eccentricity - 0.1) / 0.2 * 20; // Gradual penalty
      }
    }

    // Check orbital period (not too long, not too short)
    final period = planet.orbitalPeriod;
    if (period != null) {
      if (period < 10) {
        score -= 20; // Too close to star
      } else if (period > 500) {
        score -= 15; // Too far from star
      }
    }

    // Check semi-major axis
    final sma = planet.semiMajorAxis;
    if (sma != null) {
      // Optimal range: 0.8 - 1.5 AU (similar to Earth)
      if (sma < 0.5) {
        score -= 25;
      } else if (sma > 2.0) {
        score -= 20;
      }
    }

    return math.max(0, math.min(100, score));
  }

  String _getTemperatureAnalysis(Planet planet, double score) {
    final temp = planet.equilibriumTemperature;
    if (temp == null) return 'Temperature data not available';

    if (score >= 80) {
      return 'Excellent temperature range for liquid water and life (${temp.toStringAsFixed(1)}K / ${(temp - 273.15).toStringAsFixed(1)}°C)';
    } else if (score >= 60) {
      return 'Good temperature, within habitable zone (${temp.toStringAsFixed(1)}K / ${(temp - 273.15).toStringAsFixed(1)}°C)';
    } else if (score >= 40) {
      return 'Marginal temperature, at edge of habitable zone (${temp.toStringAsFixed(1)}K / ${(temp - 273.15).toStringAsFixed(1)}°C)';
    } else {
      return 'Temperature outside habitable range (${temp.toStringAsFixed(1)}K / ${(temp - 273.15).toStringAsFixed(1)}°C)';
    }
  }

  String _getSizeAnalysis(Planet planet, double score) {
    final radius = planet.radius;
    if (radius == null) return 'Size data not available';

    if (score >= 80) {
      return 'Ideal size for terrestrial planet (${radius.toStringAsFixed(2)} Earth radii)';
    } else if (score >= 60) {
      return 'Good size, can maintain atmosphere (${radius.toStringAsFixed(2)} Earth radii)';
    } else if (score >= 40) {
      return 'Size may pose challenges for habitability (${radius.toStringAsFixed(2)} Earth radii)';
    } else {
      return 'Size not suitable for Earth-like life (${radius.toStringAsFixed(2)} Earth radii)';
    }
  }

  String _getStarAnalysis(Planet planet, double score) {
    final starType = planet.stellarSpectralType;
    if (starType == null) return 'Star type data not available';

    if (score >= 90) {
      return 'Excellent star type ($starType) - stable and long-lived';
    } else if (score >= 70) {
      return 'Good star type ($starType) - suitable for life';
    } else if (score >= 50) {
      return 'Challenging star type ($starType) - possible habitability concerns';
    } else {
      return 'Poor star type ($starType) - not ideal for life';
    }
  }

  String _getOrbitAnalysis(Planet planet, double score) {
    if (score >= 80) {
      return 'Stable, circular orbit ideal for maintaining consistent conditions';
    } else if (score >= 60) {
      return 'Good orbital characteristics with minor variations';
    } else if (score >= 40) {
      return 'Orbital characteristics may cause temperature extremes';
    } else {
      return 'Highly elliptical or unstable orbit unsuitable for life';
    }
  }

  String _getOverallAnalysis(double score) {
    if (score >= 80) {
      return 'Highly promising candidate for habitability! This planet shows excellent conditions across multiple factors.';
    } else if (score >= 60) {
      return 'Good habitability potential. Some conditions are favorable for life, though challenges exist.';
    } else if (score >= 40) {
      return 'Marginal habitability. Significant challenges exist, but life might be possible under extreme conditions.';
    } else if (score >= 20) {
      return 'Low habitability potential. Multiple factors make life unlikely with current understanding.';
    } else {
      return 'Extremely low habitability. Conditions are hostile to life as we know it.';
    }
  }

  List<String> _identifyStrengths(
    Planet planet,
    double temp,
    double size,
    double star,
    double orbit,
  ) {
    final strengths = <String>[];

    if (temp >= 70) strengths.add('Temperature within ideal habitable zone');
    if (size >= 70)
      strengths.add('Earth-like size suitable for atmosphere retention');
    if (star >= 70) strengths.add('Orbits a stable, long-lived star');
    if (orbit >= 70)
      strengths.add('Stable circular orbit maintains steady conditions');

    if (planet.equilibriumTemperature != null &&
        planet.equilibriumTemperature! >= 273 &&
        planet.equilibriumTemperature! <= 320) {
      strengths.add('Surface temperature allows liquid water');
    }

    if (planet.eccentricity != null && planet.eccentricity! < 0.1) {
      strengths.add('Low orbital eccentricity ensures thermal stability');
    }

    return strengths;
  }

  List<String> _identifyWeaknesses(
    Planet planet,
    double temp,
    double size,
    double star,
    double orbit,
  ) {
    final weaknesses = <String>[];

    if (temp < 50)
      weaknesses.add('Temperature outside optimal habitable range');
    if (size < 50) weaknesses.add('Planet size not ideal for Earth-like life');
    if (star < 50)
      weaknesses.add('Host star type presents habitability challenges');
    if (orbit < 50)
      weaknesses.add('Orbital instability may cause extreme conditions');

    if (planet.equilibriumTemperature != null &&
        planet.equilibriumTemperature! < 200) {
      weaknesses.add('Extremely cold - likely frozen surface');
    }

    if (planet.equilibriumTemperature != null &&
        planet.equilibriumTemperature! > 400) {
      weaknesses.add('Extremely hot - likely no liquid water');
    }

    if (planet.radius != null && planet.radius! > 3.0) {
      weaknesses.add('Large size may indicate gas giant composition');
    }

    if (planet.eccentricity != null && planet.eccentricity! > 0.3) {
      weaknesses.add('High orbital eccentricity causes temperature extremes');
    }

    return weaknesses;
  }

  List<String> _generateRecommendations(
    Planet planet,
    List<String> weaknesses,
  ) {
    final recommendations = <String>[];

    if (weaknesses.any((w) => w.contains('Temperature'))) {
      recommendations.add(
        'Further study of atmospheric composition could reveal greenhouse effects',
      );
    }

    if (weaknesses.any((w) => w.contains('size'))) {
      recommendations.add(
        'Investigate planet composition and density for better habitability assessment',
      );
    }

    if (weaknesses.any((w) => w.contains('star'))) {
      recommendations.add('Analyze stellar activity and radiation levels');
    }

    if (weaknesses.any((w) => w.contains('Orbital'))) {
      recommendations.add('Model seasonal variations and climate patterns');
    }

    if (planet.distanceFromEarth != null && planet.distanceFromEarth! < 100) {
      recommendations.add(
        'Prime candidate for follow-up observations due to proximity',
      );
    }

    recommendations.add(
      'Spectroscopic analysis recommended to detect biosignatures',
    );

    return recommendations;
  }
}
