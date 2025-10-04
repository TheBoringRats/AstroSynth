import 'dart:math';

import '../models/life_form.dart';
import '../models/planet.dart';

/// Engine for simulating evolution on exoplanets
///
/// Generates life forms and evolutionary events based on:
/// - Planet's habitability score
/// - Biome type and conditions
/// - Time elapsed since planet formation
class EvolutionEngine {
  final Random _random = Random();

  /// Simulate evolution over a given time period
  ///
  /// Returns a list of life forms that evolved at different stages
  /// [planet] - The planet to simulate evolution on
  /// [yearsElapsed] - Time in millions of years (0-4000)
  /// [biomeType] - The biome classification
  /// [habitability] - Habitability score (0-100)
  List<LifeForm> simulateEvolution({
    required Planet planet,
    required int yearsElapsed,
    required String biomeType,
    required double habitability,
  }) {
    final lifeForms = <LifeForm>[];

    // No life forms if time < 500 million years (too early)
    if (yearsElapsed < 500) {
      return lifeForms;
    }

    // Calculate evolution speed based on habitability
    final evolutionSpeed = _calculateEvolutionSpeed(habitability, biomeType);

    // Generate life forms for each stage that has been reached
    final stages = _determineReachedStages(yearsElapsed, evolutionSpeed);

    for (final stage in stages) {
      final lifeForm = _generateLifeForm(
        planet: planet,
        stage: stage,
        biomeType: biomeType,
        habitability: habitability,
        yearsElapsed: yearsElapsed,
      );
      lifeForms.add(lifeForm);
    }

    return lifeForms;
  }

  /// Generate evolutionary events for a given timeline
  List<EvolutionaryEvent> generateEvents({
    required Planet planet,
    required int yearsElapsed,
    required String biomeType,
    required double habitability,
  }) {
    final events = <EvolutionaryEvent>[];

    // Origin of life event
    if (yearsElapsed >= 500) {
      events.add(
        EvolutionaryEvent(
          name: 'Abiogenesis',
          description:
              'The first self-replicating molecules emerge in ${biomeType.toLowerCase()} conditions, marking the origin of life on ${planet.displayName}.',
          yearOccurred: 500,
          type: EventType.origin,
          impactSeverity: 0.0,
        ),
      );
    }

    // Oxygenation event (if habitable enough)
    if (yearsElapsed >= 1000 && habitability > 50) {
      events.add(
        EvolutionaryEvent(
          name: 'Great Oxygenation',
          description:
              'Photosynthetic organisms begin producing oxygen, transforming the atmosphere and enabling complex life.',
          yearOccurred: 1000,
          type: EventType.oxygenation,
          impactSeverity: 0.3,
        ),
      );
    }

    // Multicellular explosion
    if (yearsElapsed >= 1500 && habitability > 55) {
      events.add(
        EvolutionaryEvent(
          name: 'Cambrian-like Explosion',
          description:
              'Rapid diversification of multicellular life leads to an explosion of new body plans and ecological niches.',
          yearOccurred: 1500,
          type: EventType.diversification,
          impactSeverity: 0.1,
        ),
      );
    }

    // Random catastrophe (asteroid impact or supervolcano)
    if (yearsElapsed >= 2000 && _random.nextDouble() > 0.3) {
      final impactYear = 2000 + _random.nextInt(1000);
      if (yearsElapsed >= impactYear) {
        events.add(
          EvolutionaryEvent(
            name: 'Mass Extinction Event',
            description:
                'A catastrophic asteroid impact or massive volcanic eruption causes widespread extinction, reshaping the evolutionary landscape.',
            yearOccurred: impactYear,
            type: EventType.catastrophe,
            impactSeverity: 0.75,
          ),
        );
      }
    }

    // Land colonization
    if (yearsElapsed >= 2500 && habitability > 60) {
      events.add(
        EvolutionaryEvent(
          name: 'Land Colonization',
          description:
              'Organisms make the monumental transition from aquatic to terrestrial environments, adapting to life on land.',
          yearOccurred: 2500,
          type: EventType.breakthrough,
          impactSeverity: 0.2,
        ),
      );
    }

    // Climate shift (ice age or warming)
    if (yearsElapsed >= 3000) {
      final isIceAge =
          biomeType.toLowerCase() == 'ice' ||
          biomeType.toLowerCase() == 'tundra';
      events.add(
        EvolutionaryEvent(
          name: isIceAge ? 'Global Glaciation' : 'Climate Warming',
          description: isIceAge
              ? 'A planetary ice age forces species to adapt or migrate to survive freezing conditions.'
              : 'Rising temperatures alter ecosystems, driving evolutionary adaptations to heat and drought.',
          yearOccurred: 3000,
          type: EventType.climateShift,
          impactSeverity: 0.5,
        ),
      );
    }

    // Intelligence emergence
    if (yearsElapsed >= 3800 && habitability > 70) {
      events.add(
        EvolutionaryEvent(
          name: 'Emergence of Intelligence',
          description:
              'A species develops advanced cognition, tool use, and culture, marking the rise of intelligent life.',
          yearOccurred: 3800,
          type: EventType.breakthrough,
          impactSeverity: 0.0,
        ),
      );
    }

    return events;
  }

  /// Calculate how quickly evolution proceeds based on conditions
  double _calculateEvolutionSpeed(double habitability, String biomeType) {
    var speed = habitability / 100.0;

    // Biome-specific modifiers
    switch (biomeType.toLowerCase()) {
      case 'temperate':
      case 'tropical':
      case 'ocean':
        speed *= 1.2; // Favorable conditions speed up evolution
        break;

      case 'ice':
      case 'tundra':
      case 'desert':
        speed *= 0.8; // Harsh conditions slow evolution
        break;

      case 'volcanic':
      case 'toxic':
        speed *= 0.6; // Extreme conditions severely slow evolution
        break;

      case 'barren':
      case 'lava':
        speed *= 0.1; // Nearly impossible for complex life
        break;
    }

    return speed.clamp(0.1, 1.5);
  }

  /// Determine which evolutionary stages have been reached
  List<EvolutionaryStage> _determineReachedStages(
    int yearsElapsed,
    double evolutionSpeed,
  ) {
    final stages = <EvolutionaryStage>[];

    // Adjusted timeline based on evolution speed
    final singleCellTime = 500;
    final multiCellTime = (1500 / evolutionSpeed).round();
    final aquaticTime = (2000 / evolutionSpeed).round();
    final landTime = (2800 / evolutionSpeed).round();
    final intelligenceTime = (3800 / evolutionSpeed).round();

    if (yearsElapsed >= singleCellTime) {
      stages.add(EvolutionaryStage.singleCell);
    }
    if (yearsElapsed >= multiCellTime) {
      stages.add(EvolutionaryStage.multiCell);
    }
    if (yearsElapsed >= aquaticTime) {
      stages.add(EvolutionaryStage.aquatic);
    }
    if (yearsElapsed >= landTime) {
      stages.add(EvolutionaryStage.land);
    }
    if (yearsElapsed >= intelligenceTime) {
      stages.add(EvolutionaryStage.intelligence);
    }

    return stages;
  }

  /// Generate a single life form for a given stage
  LifeForm _generateLifeForm({
    required Planet planet,
    required EvolutionaryStage stage,
    required String biomeType,
    required double habitability,
    required int yearsElapsed,
  }) {
    // Generate traits based on conditions
    final traits = TraitGenerator.generateTraits(
      biomeType,
      stage,
      habitability,
    );

    // Generate name
    final name = TraitGenerator.generateName(
      planet.displayName,
      biomeType,
      stage,
    );

    // Calculate complexity (increases with stage and habitability)
    final baseComplexity = _stageComplexity[stage] ?? 10.0;
    final complexity = (baseComplexity * (habitability / 100.0) * 1.2).clamp(
      5.0,
      100.0,
    );

    // Generate description
    final description = TraitGenerator.generateDescription(
      biomeType,
      stage,
      habitability,
      traits,
    );

    // Estimate when this stage evolved
    final yearEvolved = _estimateEvolutionYear(stage, yearsElapsed);

    return LifeForm(
      id: '${planet.name}_${stage.name}_${_random.nextInt(1000)}',
      name: name,
      stage: stage,
      description: description,
      traits: traits,
      complexity: complexity,
      biomeType: biomeType,
      yearEvolved: yearEvolved,
    );
  }

  /// Estimate when a particular stage evolved
  int _estimateEvolutionYear(EvolutionaryStage stage, int currentYears) {
    switch (stage) {
      case EvolutionaryStage.singleCell:
        return 500;
      case EvolutionaryStage.multiCell:
        return (currentYears * 0.4).round();
      case EvolutionaryStage.aquatic:
        return (currentYears * 0.5).round();
      case EvolutionaryStage.land:
        return (currentYears * 0.7).round();
      case EvolutionaryStage.intelligence:
        return (currentYears * 0.95).round();
    }
  }

  /// Base complexity for each stage
  static const Map<EvolutionaryStage, double> _stageComplexity = {
    EvolutionaryStage.singleCell: 10.0,
    EvolutionaryStage.multiCell: 25.0,
    EvolutionaryStage.aquatic: 45.0,
    EvolutionaryStage.land: 70.0,
    EvolutionaryStage.intelligence: 95.0,
  };

  /// Get a descriptive summary of evolution progress
  String getEvolutionSummary({
    required int yearsElapsed,
    required double habitability,
    required String biomeType,
    required List<LifeForm> lifeForms,
  }) {
    if (lifeForms.isEmpty) {
      if (yearsElapsed < 500) {
        return 'Too early for life. The planet is still forming and conditions are too volatile for self-replicating molecules to emerge.';
      } else {
        return 'No life detected. The harsh ${biomeType.toLowerCase()} conditions and low habitability (${habitability.toStringAsFixed(1)}%) have prevented the emergence of life.';
      }
    }

    final mostAdvanced = lifeForms.last;
    final stageName = mostAdvanced.stageDisplayName;

    if (mostAdvanced.stage == EvolutionaryStage.intelligence) {
      return 'Remarkable! Intelligent life has emerged on this ${biomeType.toLowerCase()} world. With a habitability score of ${habitability.toStringAsFixed(1)}%, conditions were favorable enough for consciousness to develop after ${yearsElapsed} million years of evolution.';
    } else if (mostAdvanced.stage == EvolutionaryStage.land) {
      return 'Life has successfully colonized land! After ${yearsElapsed} million years, ${stageName.toLowerCase()} have adapted to the ${biomeType.toLowerCase()} terrain. Intelligence may still emerge given more time.';
    } else if (mostAdvanced.stage == EvolutionaryStage.aquatic) {
      return 'Aquatic life thrives! Complex organisms swim in this world\'s waters after ${yearsElapsed} million years of evolution. The transition to land may occur with continued favorable conditions.';
    } else if (mostAdvanced.stage == EvolutionaryStage.multiCell) {
      return 'Multicellular life has emerged! After ${yearsElapsed} million years, simple colonial organisms have formed. This is a crucial step toward complex life.';
    } else {
      return 'Primitive life exists! Single-celled organisms have begun their evolutionary journey in the ${biomeType.toLowerCase()} environment. With ${habitability.toStringAsFixed(1)}% habitability, more complex life may develop.';
    }
  }

  /// Get stage progress for UI display
  Map<EvolutionaryStage, bool> getStageProgress(List<LifeForm> lifeForms) {
    final progress = <EvolutionaryStage, bool>{
      EvolutionaryStage.singleCell: false,
      EvolutionaryStage.multiCell: false,
      EvolutionaryStage.aquatic: false,
      EvolutionaryStage.land: false,
      EvolutionaryStage.intelligence: false,
    };

    for (final lifeForm in lifeForms) {
      progress[lifeForm.stage] = true;
    }

    return progress;
  }
}
