import 'dart:math' as math;

import '../models/atmospheric_profile.dart';
import '../models/biome.dart';
import '../models/planet.dart';

/// Service for generating scientifically plausible atmospheric compositions
/// Based on biome type, temperature, size, and stellar conditions
class AtmosphericModeler {
  static final AtmosphericModeler _instance = AtmosphericModeler._internal();
  factory AtmosphericModeler() => _instance;
  AtmosphericModeler._internal();

  final _random = math.Random();

  /// Generate atmospheric profile based on planet characteristics
  AtmosphericProfile generateAtmosphere(Planet planet, Biome biome) {
    // Classify biome and generate appropriate atmosphere
    switch (biome.type) {
      case 'Temperate':
        return _generateTemperateAtmosphere(planet);
      case 'Frozen':
      case 'Ice World':
        return _generateFrozenAtmosphere(planet);
      case 'Desert':
        return _generateDesertAtmosphere(planet);
      case 'Ocean':
      case 'Water World':
        return _generateOceanAtmosphere(planet);
      case 'Volcanic':
      case 'Lava World':
        return _generateVolcanicAtmosphere(planet);
      case 'Barren':
      case 'Rocky':
        return _generateBarrenAtmosphere(planet);
      case 'Gas Giant':
        return _generateGasGiantAtmosphere(planet);
      case 'Super-Earth':
        return _generateSuperEarthAtmosphere(planet);
      default:
        return _generateDefaultAtmosphere(planet);
    }
  }

  /// Earth-like temperate atmosphere
  AtmosphericProfile _generateTemperateAtmosphere(Planet planet) {
    // Earth-like: N2 (78%), O2 (21%), Ar (0.9%), CO2 (0.04%)
    final hasLife = _hasLifePotential(planet);

    final composition = {
      'N₂ (Nitrogen)': 75.0 + _randomVariance(5.0),
      'O₂ (Oxygen)': hasLife
          ? 18.0 + _randomVariance(4.0)
          : 3.0 + _randomVariance(2.0),
      'Ar (Argon)': 0.8 + _randomVariance(0.3),
      'CO₂ (Carbon Dioxide)': hasLife
          ? 0.04 + _randomVariance(0.05)
          : 2.0 + _randomVariance(1.0),
      'H₂O (Water Vapor)': 1.0 + _randomVariance(1.5),
      'Trace Gases': 0.5 + _randomVariance(0.3),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 0.8 + _randomVariance(0.4), // 0.4-1.2 atm
      density: 1.2 + _randomVariance(0.3), // kg/m³
      breathability: hasLife ? 'Breathable' : 'Marginally Breathable',
      dominantGas: 'Nitrogen',
      atmosphereColor: '#87CEEB', // Sky blue
      characteristics: [
        'Earth-like composition',
        'Stable temperature',
        hasLife ? 'High oxygen' : 'Low oxygen',
        'Liquid water present',
      ],
    );
  }

  /// Frozen world atmosphere (thin, CO2/N2)
  AtmosphericProfile _generateFrozenAtmosphere(Planet planet) {
    final composition = {
      'N₂ (Nitrogen)': 40.0 + _randomVariance(10.0),
      'CO₂ (Carbon Dioxide)': 35.0 + _randomVariance(10.0),
      'Ar (Argon)': 8.0 + _randomVariance(3.0),
      'CH₄ (Methane)': 12.0 + _randomVariance(5.0),
      'Ne (Neon)': 3.0 + _randomVariance(2.0),
      'Trace Gases': 2.0 + _randomVariance(1.0),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 0.005 + _randomVariance(0.01), // Very thin (Mars-like)
      density: 0.02 + _randomVariance(0.01), // kg/m³
      breathability: 'Lethal',
      dominantGas: 'Nitrogen',
      atmosphereColor: '#B0C4DE', // Light steel blue
      characteristics: [
        'Thin atmosphere',
        'Frozen CO₂ caps',
        'Extremely cold',
        'Low pressure',
      ],
    );
  }

  /// Desert atmosphere (thick CO2, hot)
  AtmosphericProfile _generateDesertAtmosphere(Planet planet) {
    final composition = {
      'CO₂ (Carbon Dioxide)': 85.0 + _randomVariance(5.0),
      'N₂ (Nitrogen)': 8.0 + _randomVariance(3.0),
      'SO₂ (Sulfur Dioxide)': 3.0 + _randomVariance(2.0),
      'H₂O (Water Vapor)': 0.5 + _randomVariance(0.5),
      'Ar (Argon)': 2.0 + _randomVariance(1.0),
      'Trace Gases': 1.5 + _randomVariance(0.5),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 90.0 + _randomVariance(20.0), // Venus-like thick
      density: 65.0 + _randomVariance(15.0), // kg/m³
      breathability: 'Lethal',
      dominantGas: 'Carbon Dioxide',
      atmosphereColor: '#FFD700', // Golden/yellow
      characteristics: [
        'Dense atmosphere',
        'Greenhouse effect',
        'High surface pressure',
        'Acidic clouds',
      ],
    );
  }

  /// Ocean world atmosphere (humid, O2-rich if life)
  AtmosphericProfile _generateOceanAtmosphere(Planet planet) {
    final hasLife = _hasLifePotential(planet);

    final composition = {
      'N₂ (Nitrogen)': 70.0 + _randomVariance(5.0),
      'O₂ (Oxygen)': hasLife
          ? 25.0 + _randomVariance(3.0)
          : 5.0 + _randomVariance(2.0),
      'H₂O (Water Vapor)': 3.0 + _randomVariance(2.0),
      'CO₂ (Carbon Dioxide)': 0.5 + _randomVariance(0.3),
      'Ar (Argon)': 1.0 + _randomVariance(0.5),
      'Trace Gases': 0.5 + _randomVariance(0.2),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 1.1 + _randomVariance(0.3), // Slightly higher than Earth
      density: 1.4 + _randomVariance(0.2), // kg/m³
      breathability: hasLife ? 'Breathable' : 'Marginally Breathable',
      dominantGas: 'Nitrogen',
      atmosphereColor: '#4682B4', // Steel blue (humid)
      characteristics: [
        'High humidity',
        'Extensive cloud cover',
        hasLife ? 'Oxygen-rich' : 'Oxygen-poor',
        'Global ocean',
      ],
    );
  }

  /// Volcanic atmosphere (SO2, CO2, ash)
  AtmosphericProfile _generateVolcanicAtmosphere(Planet planet) {
    final composition = {
      'CO₂ (Carbon Dioxide)': 65.0 + _randomVariance(10.0),
      'SO₂ (Sulfur Dioxide)': 18.0 + _randomVariance(5.0),
      'H₂S (Hydrogen Sulfide)': 8.0 + _randomVariance(3.0),
      'N₂ (Nitrogen)': 5.0 + _randomVariance(2.0),
      'H₂O (Water Vapor)': 2.0 + _randomVariance(1.0),
      'Volcanic Ash': 2.0 + _randomVariance(1.0),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 5.0 + _randomVariance(3.0), // High pressure
      density: 8.0 + _randomVariance(2.0), // kg/m³
      breathability: 'Lethal',
      dominantGas: 'Carbon Dioxide',
      atmosphereColor: '#8B0000', // Dark red/orange
      characteristics: [
        'Sulfuric acid clouds',
        'Active volcanism',
        'Toxic gases',
        'Ash particles',
      ],
    );
  }

  /// Barren atmosphere (very thin or none)
  AtmosphericProfile _generateBarrenAtmosphere(Planet planet) {
    final hasThinAtmosphere = planet.radius != null && planet.radius! > 0.3;

    if (!hasThinAtmosphere) {
      return AtmosphericProfile(
        gasComposition: {
          'He (Helium)': 60.0,
          'H₂ (Hydrogen)': 30.0,
          'Trace Solar Wind': 10.0,
        },
        pressure: 0.000001, // Nearly vacuum
        density: 0.000001, // kg/m³
        breathability: 'Lethal',
        dominantGas: 'None',
        atmosphereColor: '#2F4F4F', // Dark slate gray
        characteristics: [
          'No atmosphere',
          'Exposed to space',
          'Solar wind only',
          'Mercury-like',
        ],
      );
    }

    final composition = {
      'Ar (Argon)': 45.0 + _randomVariance(10.0),
      'Ne (Neon)': 25.0 + _randomVariance(5.0),
      'He (Helium)': 15.0 + _randomVariance(5.0),
      'N₂ (Nitrogen)': 10.0 + _randomVariance(5.0),
      'Trace Gases': 5.0 + _randomVariance(2.0),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure: 0.001 + _randomVariance(0.005), // Extremely thin
      density: 0.01 + _randomVariance(0.005), // kg/m³
      breathability: 'Lethal',
      dominantGas: 'Argon',
      atmosphereColor: '#696969', // Dim gray
      characteristics: [
        'Extremely thin',
        'Noble gases',
        'No weathering',
        'Ancient surface',
      ],
    );
  }

  /// Gas giant atmosphere (H2, He, CH4)
  AtmosphericProfile _generateGasGiantAtmosphere(Planet planet) {
    final composition = {
      'H₂ (Hydrogen)': 75.0 + _randomVariance(5.0),
      'He (Helium)': 20.0 + _randomVariance(3.0),
      'CH₄ (Methane)': 2.0 + _randomVariance(1.0),
      'NH₃ (Ammonia)': 1.5 + _randomVariance(0.5),
      'H₂O (Water Ice)': 0.8 + _randomVariance(0.3),
      'Trace Compounds': 0.7 + _randomVariance(0.3),
    };

    return AtmosphericProfile(
      gasComposition: _normalize(composition),
      pressure:
          1000.0 + _randomVariance(500.0), // Massive pressure at cloud tops
      density: 0.15 + _randomVariance(0.05), // kg/m³ (low due to H2)
      breathability: 'Lethal',
      dominantGas: 'Hydrogen',
      atmosphereColor: '#FF8C00', // Dark orange (Jupiter-like)
      characteristics: [
        'Hydrogen-helium dominated',
        'No solid surface',
        'Extreme pressures',
        'Storm systems',
      ],
    );
  }

  /// Super-Earth atmosphere (thick, varied)
  AtmosphericProfile _generateSuperEarthAtmosphere(Planet planet) {
    final temp = planet.equilibriumTemperature ?? 300;
    final isHot = temp > 400;

    if (isHot) {
      // Hot super-Earth: thick H2/He envelope
      final composition = {
        'H₂ (Hydrogen)': 60.0 + _randomVariance(10.0),
        'He (Helium)': 25.0 + _randomVariance(5.0),
        'H₂O (Water Vapor)': 8.0 + _randomVariance(3.0),
        'CO₂ (Carbon Dioxide)': 4.0 + _randomVariance(2.0),
        'CH₄ (Methane)': 2.0 + _randomVariance(1.0),
        'Trace Gases': 1.0 + _randomVariance(0.5),
      };

      return AtmosphericProfile(
        gasComposition: _normalize(composition),
        pressure: 50.0 + _randomVariance(30.0), // Very thick
        density: 3.0 + _randomVariance(1.0), // kg/m³
        breathability: 'Lethal',
        dominantGas: 'Hydrogen',
        atmosphereColor: '#FF6347', // Tomato red (hot)
        characteristics: [
          'Thick H2/He envelope',
          'High surface gravity',
          'Hot temperatures',
          'Mini-Neptune like',
        ],
      );
    } else {
      // Cool super-Earth: rocky with thick N2/CO2
      final composition = {
        'N₂ (Nitrogen)': 55.0 + _randomVariance(10.0),
        'CO₂ (Carbon Dioxide)': 30.0 + _randomVariance(10.0),
        'O₂ (Oxygen)': 8.0 + _randomVariance(3.0),
        'Ar (Argon)': 4.0 + _randomVariance(2.0),
        'H₂O (Water Vapor)': 2.0 + _randomVariance(1.0),
        'Trace Gases': 1.0 + _randomVariance(0.5),
      };

      return AtmosphericProfile(
        gasComposition: _normalize(composition),
        pressure: 10.0 + _randomVariance(5.0), // Thick
        density: 15.0 + _randomVariance(5.0), // kg/m³
        breathability: 'Toxic',
        dominantGas: 'Nitrogen',
        atmosphereColor: '#6A5ACD', // Slate blue
        characteristics: [
          'Dense atmosphere',
          'High surface gravity',
          'Potentially habitable',
          'Thick cloud cover',
        ],
      );
    }
  }

  /// Default atmosphere for unknown biomes
  AtmosphericProfile _generateDefaultAtmosphere(Planet planet) {
    final composition = {
      'N₂ (Nitrogen)': 50.0,
      'CO₂ (Carbon Dioxide)': 30.0,
      'Ar (Argon)': 10.0,
      'O₂ (Oxygen)': 5.0,
      'Trace Gases': 5.0,
    };

    return AtmosphericProfile(
      gasComposition: composition,
      pressure: 1.0,
      density: 1.2,
      breathability: 'Toxic',
      dominantGas: 'Nitrogen',
      atmosphereColor: '#778899', // Light slate gray
      characteristics: ['Unknown composition', 'Speculative model'],
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Check if planet has potential for life (affects O2 levels)
  bool _hasLifePotential(Planet planet) {
    final temp = planet.equilibriumTemperature;
    final radius = planet.radius;

    if (temp == null || radius == null) return false;

    // Liquid water range + Earth-like size
    return temp >= 273 && temp <= 373 && radius >= 0.5 && radius <= 2.0;
  }

  /// Add random variance to a value
  double _randomVariance(double maxVariance) {
    return (_random.nextDouble() - 0.5) * 2 * maxVariance;
  }

  /// Normalize gas composition to sum to 100%
  Map<String, double> _normalize(Map<String, double> composition) {
    final total = composition.values.fold(0.0, (sum, val) => sum + val);
    final normalized = <String, double>{};

    composition.forEach((gas, percentage) {
      normalized[gas] = (percentage / total) * 100.0;
    });

    return normalized;
  }
}
