/// Represents a stage in planetary evolution
class EvolutionStage {
  final String name;
  final String description;
  final double ageInYears; // in years
  final double temperatureModifier; // multiplier for base temperature
  final double atmosphereModifier; // atmospheric thickness modifier
  final String biomeType;
  final List<String> characteristics;
  final String stellarPhase; // Main Sequence, Red Giant, White Dwarf, etc.
  final double stellarLuminosity; // relative to current

  EvolutionStage({
    required this.name,
    required this.description,
    required this.ageInYears,
    required this.temperatureModifier,
    required this.atmosphereModifier,
    required this.biomeType,
    required this.characteristics,
    required this.stellarPhase,
    required this.stellarLuminosity,
  });

  /// Get age in millions of years
  double get ageInMillions => ageInYears / 1e6;

  /// Get age in billions of years
  double get ageInBillions => ageInYears / 1e9;

  /// Format age for display
  String get formattedAge {
    if (ageInBillions >= 1) {
      return '${ageInBillions.toStringAsFixed(1)} Billion Years';
    } else if (ageInMillions >= 1) {
      return '${ageInMillions.toStringAsFixed(0)} Million Years';
    } else {
      return '${(ageInYears / 1e3).toStringAsFixed(0)} Thousand Years';
    }
  }

  /// Predefined evolution stages
  static EvolutionStage formation() {
    return EvolutionStage(
      name: 'Formation',
      description:
          'Protoplanetary disk coalesces into a molten world. Heavy bombardment from asteroids and comets. Surface is a sea of magma.',
      ageInYears: 1e8, // 100 million years
      temperatureModifier: 3.0,
      atmosphereModifier: 0.1,
      biomeType: 'Lava World',
      characteristics: [
        'Molten surface (>2000K)',
        'Heavy asteroid bombardment',
        'Thin primordial atmosphere',
        'Intense volcanic activity',
        'No solid crust',
        'Water exists only as vapor',
      ],
      stellarPhase: 'Young Main Sequence',
      stellarLuminosity: 0.7, // Young stars are dimmer
    );
  }

  static EvolutionStage early() {
    return EvolutionStage(
      name: 'Early',
      description:
          'Crust solidifies and oceans form from comet impacts. Primitive atmosphere develops. First continents emerge.',
      ageInYears: 8e8, // 800 million years
      temperatureModifier: 1.5,
      atmosphereModifier: 0.5,
      biomeType: 'Volcanic',
      characteristics: [
        'Solid crust forms',
        'Early oceans from comets',
        'Active plate tectonics',
        'CO₂-rich atmosphere',
        'Frequent volcanic eruptions',
        'Potential for prebiotic chemistry',
      ],
      stellarPhase: 'Main Sequence',
      stellarLuminosity: 0.85,
    );
  }

  static EvolutionStage stable() {
    return EvolutionStage(
      name: 'Stable (Current)',
      description:
          'Mature planet with established climate. If conditions are right, complex life may evolve. This is the optimal period for habitability.',
      ageInYears: 4.5e9, // 4.5 billion years (Earth\'s current age)
      temperatureModifier: 1.0,
      atmosphereModifier: 1.0,
      biomeType: 'Temperate',
      characteristics: [
        'Stable climate',
        'Mature atmosphere',
        'Established water cycle',
        'Peak habitability window',
        'Complex ecosystems possible',
        'Magnetic field protects surface',
      ],
      stellarPhase: 'Main Sequence',
      stellarLuminosity: 1.0,
    );
  }

  static EvolutionStage aging() {
    return EvolutionStage(
      name: 'Aging',
      description:
          'Host star brightens as it ages. Oceans begin to evaporate. Greenhouse effect intensifies. Habitable zone shifts outward.',
      ageInYears: 6e9, // 6 billion years
      temperatureModifier: 1.4,
      atmosphereModifier: 0.8,
      biomeType: 'Desert',
      characteristics: [
        'Rising temperatures',
        'Evaporating oceans',
        'Runaway greenhouse effect begins',
        'Decreased plate tectonics',
        'Weakening magnetic field',
        'Life struggles to survive',
      ],
      stellarPhase: 'Evolved Main Sequence',
      stellarLuminosity: 1.4,
    );
  }

  static EvolutionStage endStage() {
    return EvolutionStage(
      name: 'End Stage',
      description:
          'Star enters red giant phase, engulfing inner planets. Outer planets may become habitable. This world\'s story ends.',
      ageInYears: 1e10, // 10 billion years
      temperatureModifier: 5.0,
      atmosphereModifier: 0.05,
      biomeType: 'Barren',
      characteristics: [
        'Star becomes red giant',
        'Extreme surface temperatures (>1000K)',
        'Atmosphere stripped away',
        'Oceans completely evaporated',
        'Surface is lifeless desert',
        'Magnetic field collapsed',
      ],
      stellarPhase: 'Red Giant',
      stellarLuminosity: 100.0, // Red giants are extremely luminous
    );
  }

  /// Get all evolution stages in order
  static List<EvolutionStage> getAllStages() {
    return [formation(), early(), stable(), aging(), endStage()];
  }

  /// Get stage by index
  static EvolutionStage getStage(int index) {
    final stages = getAllStages();
    return stages[index.clamp(0, stages.length - 1)];
  }

  /// Get stage by age in years
  static EvolutionStage getStageByAge(double ageInYears) {
    if (ageInYears < 5e8) return formation();
    if (ageInYears < 2e9) return early();
    if (ageInYears < 5.5e9) return stable();
    if (ageInYears < 8e9) return aging();
    return endStage();
  }

  /// Interpolate between two stages
  static EvolutionStage interpolate(
    EvolutionStage stage1,
    EvolutionStage stage2,
    double t, // 0.0 to 1.0
  ) {
    return EvolutionStage(
      name: '${stage1.name} → ${stage2.name}',
      description: stage2.description,
      ageInYears:
          stage1.ageInYears + (stage2.ageInYears - stage1.ageInYears) * t,
      temperatureModifier:
          stage1.temperatureModifier +
          (stage2.temperatureModifier - stage1.temperatureModifier) * t,
      atmosphereModifier:
          stage1.atmosphereModifier +
          (stage2.atmosphereModifier - stage1.atmosphereModifier) * t,
      biomeType: t < 0.5 ? stage1.biomeType : stage2.biomeType,
      characteristics: t < 0.5
          ? stage1.characteristics
          : stage2.characteristics,
      stellarPhase: t < 0.5 ? stage1.stellarPhase : stage2.stellarPhase,
      stellarLuminosity:
          stage1.stellarLuminosity +
          (stage2.stellarLuminosity - stage1.stellarLuminosity) * t,
    );
  }
}
