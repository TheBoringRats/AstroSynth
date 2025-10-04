import '../models/atmospheric_profile.dart';
import '../models/biome.dart';
import '../models/evolution_stage.dart';
import '../models/planet.dart';

/// Service for simulating planetary evolution over billions of years
class PlanetEvolutionSimulator {
  static final PlanetEvolutionSimulator _instance =
      PlanetEvolutionSimulator._internal();
  factory PlanetEvolutionSimulator() => _instance;
  PlanetEvolutionSimulator._internal();

  /// Simulate planet at a specific age
  PlanetSnapshot simulateAtAge(Planet basePlanet, double ageInYears) {
    final stage = EvolutionStage.getStageByAge(ageInYears);

    // Calculate modified parameters
    final temperature = _calculateTemperatureAtAge(
      basePlanet.equilibriumTemperature ?? 280,
      stage,
    );

    final atmosphere = _generateAtmosphereForStage(
      basePlanet,
      stage,
      temperature,
    );

    final biome = Biome.classify(
      temperature: temperature,
      radius: basePlanet.radius ?? 1.0,
      mass: basePlanet.mass ?? 1.0,
    );

    final habitability = _calculateHabitabilityAtAge(
      basePlanet,
      temperature,
      stage,
    );

    return PlanetSnapshot(
      age: ageInYears,
      stage: stage,
      temperature: temperature,
      atmosphere: atmosphere,
      biome: biome,
      habitability: habitability,
      hasOceans: _hasOceansAtAge(temperature, stage),
      hasLife: _hasLifeAtAge(habitability, stage),
      volcanicActivity: _getVolcanicActivity(stage),
      magneticFieldStrength: _getMagneticFieldStrength(basePlanet, stage),
    );
  }

  /// Calculate temperature at specific evolutionary age
  double _calculateTemperatureAtAge(
    double baseTemperature,
    EvolutionStage stage,
  ) {
    // Account for stellar evolution (star gets brighter over time)
    final stellarEffect =
        baseTemperature * (stage.stellarLuminosity - 1.0) * 0.3;

    // Account for atmospheric changes
    final atmosphericEffect =
        baseTemperature * (stage.atmosphereModifier - 1.0) * 0.2;

    // Direct stage temperature modifier
    final stageEffect = baseTemperature * (stage.temperatureModifier - 1.0);

    return baseTemperature + stellarEffect + atmosphericEffect + stageEffect;
  }

  /// Generate atmospheric composition for evolutionary stage
  AtmosphericProfile _generateAtmosphereForStage(
    Planet planet,
    EvolutionStage stage,
    double temperature,
  ) {
    Map<String, double> gases = {};
    double pressure = 1.0;
    String breathability = 'Lethal';

    switch (stage.name) {
      case 'Formation':
        // Hot, thin primordial atmosphere
        gases = {'H₂': 70.0, 'He': 20.0, 'H₂O': 5.0, 'CO': 3.0, 'CH₄': 2.0};
        pressure = 0.1 * stage.atmosphereModifier;
        breathability = 'Lethal';
        break;

      case 'Early':
        // Volcanic outgassing creates thick CO₂ atmosphere
        gases = {'CO₂': 75.0, 'N₂': 15.0, 'SO₂': 5.0, 'H₂O': 3.0, 'CH₄': 2.0};
        pressure = 2.0 * stage.atmosphereModifier;
        breathability = 'Lethal';
        break;

      case 'Stable (Current)':
        // Mature atmosphere, possibly with life
        if (temperature >= 273 && temperature <= 323) {
          // Habitable zone - Earth-like
          gases = {'N₂': 78.0, 'O₂': 21.0, 'Ar': 0.9, 'CO₂': 0.04, 'H₂O': 0.06};
          breathability = 'Breathable';
        } else {
          // Too hot or cold
          gases = {'N₂': 60.0, 'CO₂': 30.0, 'Ar': 5.0, 'CH₄': 3.0, 'O₂': 2.0};
          breathability = 'Toxic';
        }
        pressure = 1.0 * stage.atmosphereModifier;
        break;

      case 'Aging':
        // Evaporating oceans, water vapor greenhouse
        gases = {'H₂O': 40.0, 'CO₂': 35.0, 'N₂': 20.0, 'SO₂': 3.0, 'O₂': 2.0};
        pressure = 0.6 * stage.atmosphereModifier;
        breathability = 'Lethal';
        break;

      case 'End Stage':
        // Atmosphere mostly stripped away
        gases = {'CO₂': 60.0, 'N₂': 30.0, 'Ar': 10.0};
        pressure = 0.05 * stage.atmosphereModifier;
        breathability = 'Lethal';
        break;

      default:
        gases = {'N₂': 78.0, 'O₂': 21.0, 'Ar': 1.0};
        pressure = 1.0;
    }

    // Find dominant gas
    String dominantGas = 'N₂';
    double maxPercentage = 0.0;
    gases.forEach((gas, percentage) {
      if (percentage > maxPercentage) {
        maxPercentage = percentage;
        dominantGas = gas;
      }
    });

    // Determine atmosphere color based on dominant gas and temperature
    String atmosphereColor = '#87CEEB'; // Default sky blue
    if (temperature > 1000) {
      atmosphereColor = '#FF6347'; // Hot red/orange
    } else if (dominantGas == 'CO₂') {
      atmosphereColor = '#E67E22'; // Orange
    } else if (dominantGas == 'H₂O') {
      atmosphereColor = '#1ABC9C'; // Turquoise
    } else if (dominantGas == 'SO₂') {
      atmosphereColor = '#F39C12'; // Yellow
    }

    return AtmosphericProfile(
      gasComposition: gases,
      pressure: pressure,
      density: pressure * 1.225, // Approximate
      breathability: breathability,
      dominantGas: dominantGas,
      atmosphereColor: atmosphereColor,
      characteristics: stage.characteristics,
    );
  }

  /// Calculate habitability score at specific age
  double _calculateHabitabilityAtAge(
    Planet planet,
    double temperature,
    EvolutionStage stage,
  ) {
    double score = 50.0; // Base score

    // Temperature factor (optimal 273-323K)
    if (temperature >= 273 && temperature <= 323) {
      score += 25.0;
    } else if (temperature >= 200 && temperature <= 400) {
      score += 10.0;
    } else {
      score -= 20.0;
    }

    // Stage-specific modifiers
    switch (stage.name) {
      case 'Formation':
        score = score * 0.1; // Almost uninhabitable
        break;
      case 'Early':
        score = score * 0.4; // Harsh but potential
        break;
      case 'Stable (Current)':
        score = score * 1.2; // Peak habitability
        break;
      case 'Aging':
        score = score * 0.6; // Declining
        break;
      case 'End Stage':
        score = score * 0.05; // Nearly dead
        break;
    }

    // Planet size factor
    final radius = planet.radius ?? 1.0;
    if (radius >= 0.8 && radius <= 1.5) {
      score += 10.0;
    }

    // Stellar luminosity factor
    if (stage.stellarLuminosity > 2.0) {
      score -= 30.0; // Too bright = too hot
    }

    return score.clamp(0.0, 100.0);
  }

  /// Check if planet has oceans at this age
  bool _hasOceansAtAge(double temperature, EvolutionStage stage) {
    // Water is liquid between 273K and 373K at 1 atm
    if (temperature < 273 || temperature > 373) return false;

    // Oceans don't exist in early formation
    if (stage.name == 'Formation') return false;

    // Oceans evaporated in end stage
    if (stage.name == 'End Stage') return false;

    return true;
  }

  /// Check if planet could support life at this age
  bool _hasLifeAtAge(double habitability, EvolutionStage stage) {
    // Life requires stable period and decent habitability
    if (habitability < 30.0) return false;

    // No life during formation
    if (stage.name == 'Formation') return false;

    // Rare but possible in early stage
    if (stage.name == 'Early') return habitability > 40.0;

    // Most likely during stable period
    if (stage.name == 'Stable (Current)') return habitability > 30.0;

    // Declining in aging stage
    if (stage.name == 'Aging') return habitability > 50.0;

    // No life in end stage
    return false;
  }

  /// Get volcanic activity level
  String _getVolcanicActivity(EvolutionStage stage) {
    switch (stage.name) {
      case 'Formation':
        return 'Extreme';
      case 'Early':
        return 'High';
      case 'Stable (Current)':
        return 'Moderate';
      case 'Aging':
        return 'Low';
      case 'End Stage':
        return 'None';
      default:
        return 'Moderate';
    }
  }

  /// Calculate magnetic field strength
  double _getMagneticFieldStrength(Planet planet, EvolutionStage stage) {
    // Depends on core temperature and rotation
    final baseMass = planet.mass ?? 1.0;
    double strength = baseMass * 100.0; // Base magnetic field

    // Modify by age
    switch (stage.name) {
      case 'Formation':
        strength *= 0.5; // Weak, core still forming
        break;
      case 'Early':
        strength *= 0.8; // Strengthening
        break;
      case 'Stable (Current)':
        strength *= 1.0; // Peak strength
        break;
      case 'Aging':
        strength *= 0.6; // Weakening
        break;
      case 'End Stage':
        strength *= 0.1; // Nearly gone
        break;
    }

    return strength;
  }

  /// Generate timeline of snapshots
  List<PlanetSnapshot> generateTimeline(Planet planet, int numPoints) {
    final snapshots = <PlanetSnapshot>[];
    final maxAge = 1e10; // 10 billion years

    for (int i = 0; i < numPoints; i++) {
      final age = (maxAge / (numPoints - 1)) * i;
      snapshots.add(simulateAtAge(planet, age));
    }

    return snapshots;
  }
}

/// Snapshot of planet at specific evolutionary age
class PlanetSnapshot {
  final double age; // in years
  final EvolutionStage stage;
  final double temperature;
  final AtmosphericProfile atmosphere;
  final Biome biome;
  final double habitability;
  final bool hasOceans;
  final bool hasLife;
  final String volcanicActivity;
  final double magneticFieldStrength;

  PlanetSnapshot({
    required this.age,
    required this.stage,
    required this.temperature,
    required this.atmosphere,
    required this.biome,
    required this.habitability,
    required this.hasOceans,
    required this.hasLife,
    required this.volcanicActivity,
    required this.magneticFieldStrength,
  });

  String get formattedAge => stage.formattedAge;
}
