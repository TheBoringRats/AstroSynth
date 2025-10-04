import 'dart:math' as math;

import '../models/enhanced_habitability_result.dart';
import '../models/planet.dart';
import '../services/enhanced_habitability_calculator.dart';

/// Parameters that can be adjusted in the terraform simulator
class TerraformParameters {
  // Atmospheric composition (percentages, sum to 100)
  double nitrogenPercent;
  double oxygenPercent;
  double carbonDioxidePercent;
  double waterVaporPercent;
  double argonPercent;

  // Physical parameters
  double waterCoverage; // 0-100%
  double orbitalDistance; // in AU
  double planetMass; // in Earth masses
  double planetRadius; // in Earth radii
  bool hasMoon;

  // Original values (for reset)
  final double originalNitrogen;
  final double originalOxygen;
  final double originalCO2;
  final double originalWaterVapor;
  final double originalArgon;
  final double originalWaterCoverage;
  final double originalOrbitalDistance;
  final double originalMass;
  final double originalRadius;
  final bool originalHasMoon;

  TerraformParameters({
    required this.nitrogenPercent,
    required this.oxygenPercent,
    required this.carbonDioxidePercent,
    required this.waterVaporPercent,
    required this.argonPercent,
    required this.waterCoverage,
    required this.orbitalDistance,
    required this.planetMass,
    required this.planetRadius,
    required this.hasMoon,
  }) : originalNitrogen = nitrogenPercent,
       originalOxygen = oxygenPercent,
       originalCO2 = carbonDioxidePercent,
       originalWaterVapor = waterVaporPercent,
       originalArgon = argonPercent,
       originalWaterCoverage = waterCoverage,
       originalOrbitalDistance = orbitalDistance,
       originalMass = planetMass,
       originalRadius = planetRadius,
       originalHasMoon = hasMoon;

  /// Create from planet
  factory TerraformParameters.fromPlanet(Planet planet) {
    return TerraformParameters(
      nitrogenPercent: 78.0, // Default Earth-like
      oxygenPercent: 21.0,
      carbonDioxidePercent: 0.04,
      waterVaporPercent: 0.4,
      argonPercent: 0.56,
      waterCoverage: 50.0,
      orbitalDistance: planet.semiMajorAxis ?? 1.0,
      planetMass: planet.mass ?? 1.0,
      planetRadius: planet.radius ?? 1.0,
      hasMoon: planet.mass != null && planet.mass! > 0.5,
    );
  }

  /// Reset to original values
  void reset() {
    nitrogenPercent = originalNitrogen;
    oxygenPercent = originalOxygen;
    carbonDioxidePercent = originalCO2;
    waterVaporPercent = originalWaterVapor;
    argonPercent = originalArgon;
    waterCoverage = originalWaterCoverage;
    orbitalDistance = originalOrbitalDistance;
    planetMass = originalMass;
    planetRadius = originalRadius;
    hasMoon = originalHasMoon;
  }

  /// Get total atmospheric percentage
  double get totalAtmosphere =>
      nitrogenPercent +
      oxygenPercent +
      carbonDioxidePercent +
      waterVaporPercent +
      argonPercent;

  /// Normalize atmospheric composition to 100%
  void normalizeAtmosphere() {
    final total = totalAtmosphere;
    if (total > 0) {
      nitrogenPercent = (nitrogenPercent / total) * 100;
      oxygenPercent = (oxygenPercent / total) * 100;
      carbonDioxidePercent = (carbonDioxidePercent / total) * 100;
      waterVaporPercent = (waterVaporPercent / total) * 100;
      argonPercent = (argonPercent / total) * 100;
    }
  }
}

/// Engine for calculating habitability changes based on terraforming parameters
class TerraformingEngine {
  static final TerraformingEngine _instance = TerraformingEngine._internal();
  factory TerraformingEngine() => _instance;
  TerraformingEngine._internal();

  final EnhancedHabitabilityCalculator _calculator =
      EnhancedHabitabilityCalculator();

  /// Calculate new habitability based on terraform parameters
  EnhancedHabitabilityResult calculateTerraformedHabitability(
    Planet originalPlanet,
    TerraformParameters params,
  ) {
    // Create a modified planet with new parameters
    final terraformedPlanet = _applyTerraformParameters(originalPlanet, params);

    // Calculate habitability with enhanced calculator
    return _calculator.calculateHabitability(terraformedPlanet);
  }

  /// Apply terraform parameters to create a modified planet
  Planet _applyTerraformParameters(
    Planet original,
    TerraformParameters params,
  ) {
    // Calculate new equilibrium temperature based on orbital distance
    final newTemp = _calculateTemperature(
      original,
      params.orbitalDistance,
      params.waterCoverage,
      params.carbonDioxidePercent,
    );

    // Create modified planet
    return original.copyWith(
      mass: params.planetMass,
      radius: params.planetRadius,
      semiMajorAxis: params.orbitalDistance,
      equilibriumTemperature: newTemp,
      // Eccentricity changes if we add/remove moon
      eccentricity: params.hasMoon
          ? math.min(original.eccentricity ?? 0.05, 0.05)
          : (original.eccentricity ?? 0.1),
    );
  }

  /// Calculate new equilibrium temperature
  double _calculateTemperature(
    Planet planet,
    double orbitalDistance,
    double waterCoverage,
    double co2Percent,
  ) {
    final starTemp = planet.stellarTemperature ?? 5778; // Sun-like default
    final starRadius = planet.stellarRadius ?? 1.0;

    // Stefan-Boltzmann law: T = T_star * sqrt(R_star / 2*d)
    final baseTemp = starTemp * math.sqrt(starRadius / (2 * orbitalDistance));

    // Greenhouse effect from CO2
    final greenhouseEffect =
        1.0 + (co2Percent / 100 * 0.6); // Up to 60% warming

    // Albedo effect from water coverage (water is darker than land)
    final albedoFactor =
        1.0 - (waterCoverage / 100 * 0.1); // Up to 10% less reflection

    return baseTemp * greenhouseEffect * albedoFactor;
  }

  /// Get biome type based on parameters
  String getBiomeType(TerraformParameters params, double temperature) {
    // Frozen
    if (temperature < 250) return 'Frozen';

    // Ice World
    if (temperature < 273) return 'Ice World';

    // Temperate (ideal)
    if (temperature >= 273 &&
        temperature <= 323 &&
        params.waterCoverage >= 20 &&
        params.waterCoverage <= 80 &&
        params.oxygenPercent >= 15) {
      return 'Temperate';
    }

    // Ocean World
    if (params.waterCoverage > 80 && temperature >= 273 && temperature <= 323) {
      return 'Ocean';
    }

    // Desert
    if (temperature > 323 && temperature < 400 && params.waterCoverage < 20) {
      return 'Desert';
    }

    // Volcanic/Lava
    if (temperature > 400) return 'Volcanic';

    // Barren (no atmosphere, no water)
    if (params.totalAtmosphere < 50 || params.waterCoverage < 5) {
      return 'Barren';
    }

    return 'Rocky';
  }

  /// Get breathability assessment
  String getBreathability(TerraformParameters params) {
    // Check oxygen levels
    if (params.oxygenPercent < 10) return 'Lethal';
    if (params.oxygenPercent < 15) return 'Toxic';
    if (params.oxygenPercent < 18) return 'Marginally Breathable';

    // Check toxic gases
    if (params.carbonDioxidePercent > 5) return 'Toxic';
    if (params.carbonDioxidePercent > 1) return 'Marginally Breathable';

    // Check pressure (nitrogen as proxy)
    if (params.nitrogenPercent < 50 || params.nitrogenPercent > 85) {
      return 'Marginally Breathable';
    }

    return 'Breathable';
  }

  /// Get color for planet visualization
  String getPlanetColor(String biome, double waterCoverage) {
    switch (biome) {
      case 'Temperate':
        return waterCoverage > 50 ? '#4169E1' : '#228B22'; // Blue-green
      case 'Ocean':
        return '#1E90FF'; // Deep blue
      case 'Frozen':
      case 'Ice World':
        return '#B0E0E6'; // Powder blue
      case 'Desert':
        return '#DEB887'; // Burlywood
      case 'Volcanic':
        return '#FF4500'; // Orange-red
      case 'Barren':
      case 'Rocky':
        return '#A0522D'; // Sienna
      default:
        return '#808080'; // Gray
    }
  }

  /// Generate comparison summary
  Map<String, dynamic> generateComparison(
    EnhancedHabitabilityResult original,
    EnhancedHabitabilityResult terraformed,
  ) {
    final scoreDiff = terraformed.overallScore - original.overallScore;
    final improvementPercent = (scoreDiff / original.overallScore) * 100;

    return {
      'originalScore': original.overallScore,
      'terraformedScore': terraformed.overallScore,
      'scoreDifference': scoreDiff,
      'improvementPercent': improvementPercent,
      'isImproved': scoreDiff > 0,
      'significantChange': scoreDiff.abs() > 10,
      'originalCategory': original.category,
      'terraformedCategory': terraformed.category,
      'categoryChanged': original.category != terraformed.category,
    };
  }
}
