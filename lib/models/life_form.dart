/// Represents a life form that could evolve on an exoplanet
///
/// This model defines the characteristics of organisms that might develop
/// based on a planet's biome, habitability, and time elapsed since formation.
class LifeForm {
  final String id;
  final String name;
  final EvolutionaryStage stage;
  final String description;
  final List<String> traits;
  final double complexity; // 0-100 based on evolutionary progress
  final String biomeType;
  final int yearEvolved; // Million years ago
  final String? imageAsset; // Path to illustration (optional)

  const LifeForm({
    required this.id,
    required this.name,
    required this.stage,
    required this.description,
    required this.traits,
    required this.complexity,
    required this.biomeType,
    required this.yearEvolved,
    this.imageAsset,
  });

  /// Creates a copy with modified fields
  LifeForm copyWith({
    String? id,
    String? name,
    EvolutionaryStage? stage,
    String? description,
    List<String>? traits,
    double? complexity,
    String? biomeType,
    int? yearEvolved,
    String? imageAsset,
  }) {
    return LifeForm(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      description: description ?? this.description,
      traits: traits ?? this.traits,
      complexity: complexity ?? this.complexity,
      biomeType: biomeType ?? this.biomeType,
      yearEvolved: yearEvolved ?? this.yearEvolved,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  /// Get stage display name
  String get stageDisplayName => _stageNames[stage] ?? 'Unknown';

  /// Get stage icon
  String get stageIcon => _stageIcons[stage] ?? '🦠';

  /// Get trait display string
  String get traitsDisplay => traits.join(', ');

  /// Check if this is an intelligent species
  bool get isIntelligent => stage == EvolutionaryStage.intelligence;

  /// Get complexity category
  String get complexityCategory {
    if (complexity < 20) return 'Simple';
    if (complexity < 40) return 'Basic';
    if (complexity < 60) return 'Moderate';
    if (complexity < 80) return 'Complex';
    return 'Highly Complex';
  }

  static const Map<EvolutionaryStage, String> _stageNames = {
    EvolutionaryStage.singleCell: 'Single-Cell Organisms',
    EvolutionaryStage.multiCell: 'Multicellular Life',
    EvolutionaryStage.aquatic: 'Aquatic Creatures',
    EvolutionaryStage.land: 'Land-Based Life',
    EvolutionaryStage.intelligence: 'Intelligent Species',
  };

  static const Map<EvolutionaryStage, String> _stageIcons = {
    EvolutionaryStage.singleCell: '🦠',
    EvolutionaryStage.multiCell: '🧬',
    EvolutionaryStage.aquatic: '🐟',
    EvolutionaryStage.land: '🦎',
    EvolutionaryStage.intelligence: '🧠',
  };

  @override
  String toString() =>
      'LifeForm($name, $stage, ${complexity.toInt()}% complex)';
}

/// Evolutionary stages that life progresses through
enum EvolutionaryStage {
  /// Prokaryotes and eukaryotes (bacteria, archaea)
  singleCell,

  /// Simple multicellular organisms (sponges, early plants)
  multiCell,

  /// Marine and freshwater life (fish, amphibians)
  aquatic,

  /// Terrestrial organisms (reptiles, mammals, plants)
  land,

  /// Tool-using, self-aware species
  intelligence,
}

/// Represents a significant event in planetary evolution
class EvolutionaryEvent {
  final String name;
  final String description;
  final int yearOccurred; // Million years ago
  final EventType type;
  final double impactSeverity; // 0-1, where 1 is extinction-level

  const EvolutionaryEvent({
    required this.name,
    required this.description,
    required this.yearOccurred,
    required this.type,
    required this.impactSeverity,
  });

  /// Get event icon
  String get icon => _eventIcons[type] ?? '⚡';

  /// Check if this was a mass extinction
  bool get isMassExtinction =>
      impactSeverity > 0.7 && type == EventType.catastrophe;

  static const Map<EventType, String> _eventIcons = {
    EventType.origin: '🌱',
    EventType.diversification: '🌿',
    EventType.catastrophe: '☄️',
    EventType.climateShift: '🌡️',
    EventType.oxygenation: '💨',
    EventType.breakthrough: '✨',
  };
}

/// Types of evolutionary events
enum EventType {
  /// Life begins
  origin,

  /// Rapid increase in species diversity
  diversification,

  /// Asteroid impact, volcanic eruption, etc.
  catastrophe,

  /// Ice age, warming period, etc.
  climateShift,

  /// Atmosphere composition changes
  oxygenation,

  /// Major evolutionary innovation (photosynthesis, eyes, etc.)
  breakthrough,
}

/// Helper class to generate biome-appropriate traits
class TraitGenerator {
  /// Generate traits based on biome type
  static List<String> generateTraits(
    String biomeType,
    EvolutionaryStage stage,
    double habitability,
  ) {
    final traits = <String>[];

    // Stage-based traits
    switch (stage) {
      case EvolutionaryStage.singleCell:
        traits.addAll(['Microscopic', 'Chemosynthetic']);
        if (habitability > 60) traits.add('Photosynthetic');
        break;

      case EvolutionaryStage.multiCell:
        traits.addAll(['Multicellular', 'Simple nervous system']);
        if (habitability > 70) traits.add('Colonial behavior');
        break;

      case EvolutionaryStage.aquatic:
        traits.addAll(['Gills', 'Streamlined body']);
        if (habitability > 65) {
          traits.add('Predatory');
        } else {
          traits.add('Filter feeder');
        }
        break;

      case EvolutionaryStage.land:
        traits.addAll(['Lungs', 'Four limbs']);
        if (habitability > 70) {
          traits.add('Warm-blooded');
        } else {
          traits.add('Cold-blooded');
        }
        break;

      case EvolutionaryStage.intelligence:
        traits.addAll(['Large brain', 'Tool use', 'Complex language']);
        if (habitability > 75) traits.add('Social structures');
        break;
    }

    // Biome-specific adaptations
    switch (biomeType.toLowerCase()) {
      case 'ice':
      case 'tundra':
        traits.addAll(['Thick insulation', 'Anti-freeze proteins']);
        break;

      case 'desert':
        traits.addAll(['Water retention', 'Nocturnal behavior']);
        break;

      case 'tropical':
        traits.addAll(['Rapid metabolism', 'Vibrant coloration']);
        break;

      case 'ocean':
        if (stage.index >= EvolutionaryStage.aquatic.index) {
          traits.addAll(['Deep diving', 'Bioluminescence']);
        }
        break;

      case 'volcanic':
        traits.addAll(['Heat resistant', 'Extremophile']);
        break;

      case 'toxic':
        traits.addAll(['Toxin immunity', 'Anaerobic respiration']);
        break;

      case 'temperate':
        traits.addAll(['Seasonal adaptation', 'Omnivorous']);
        break;
    }

    return traits.take(5).toList(); // Limit to 5 most relevant traits
  }

  /// Generate a descriptive name for a life form
  static String generateName(
    String planetName,
    String biomeType,
    EvolutionaryStage stage,
  ) {
    final cleanPlanetName = planetName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    switch (stage) {
      case EvolutionaryStage.singleCell:
        return '$cleanPlanetName Microbe';
      case EvolutionaryStage.multiCell:
        return '$cleanPlanetName ${_biomePrefixes[biomeType] ?? ""}Polyp';
      case EvolutionaryStage.aquatic:
        return '$cleanPlanetName ${_biomePrefixes[biomeType] ?? ""}Fish';
      case EvolutionaryStage.land:
        return '$cleanPlanetName ${_biomePrefixes[biomeType] ?? ""}Beast';
      case EvolutionaryStage.intelligence:
        return '$cleanPlanetName ${_biomePrefixes[biomeType] ?? ""}Sapient';
    }
  }

  static const Map<String, String> _biomePrefixes = {
    'ice': 'Cryo',
    'tundra': 'Frost',
    'desert': 'Xeric',
    'tropical': 'Hydro',
    'ocean': 'Abyssal',
    'volcanic': 'Pyro',
    'toxic': 'Chemo',
    'temperate': 'Gaia',
    'barren': 'Litho',
    'lava': 'Magma',
  };

  /// Generate a description of the life form
  static String generateDescription(
    String biomeType,
    EvolutionaryStage stage,
    double habitability,
    List<String> traits,
  ) {
    final descriptions = <String>[];

    // Stage-based description
    switch (stage) {
      case EvolutionaryStage.singleCell:
        descriptions.add(
          'Primitive single-celled organisms that emerged in the ${biomeType.toLowerCase()} environment.',
        );
        if (habitability > 60) {
          descriptions.add(
            'These early life forms harness energy from their surroundings to survive and reproduce.',
          );
        } else {
          descriptions.add(
            'Despite harsh conditions, these resilient microbes found ways to metabolize available resources.',
          );
        }
        break;

      case EvolutionaryStage.multiCell:
        descriptions.add(
          'Simple multicellular organisms that evolved from colonies of single-celled ancestors.',
        );
        descriptions.add(
          'They display basic coordination between cells and primitive sensory capabilities.',
        );
        break;

      case EvolutionaryStage.aquatic:
        descriptions.add(
          'Aquatic creatures adapted to life in the planet\'s water bodies.',
        );
        if (habitability > 70) {
          descriptions.add(
            'A diverse ecosystem of predators and prey has developed, with complex behaviors emerging.',
          );
        } else {
          descriptions.add(
            'These hardy organisms survive in challenging aquatic conditions through specialized adaptations.',
          );
        }
        break;

      case EvolutionaryStage.land:
        descriptions.add(
          'Land-dwelling organisms that made the transition from aquatic to terrestrial life.',
        );
        descriptions.add(
          'They have evolved respiratory and skeletal systems suited for the ${biomeType.toLowerCase()} terrain.',
        );
        break;

      case EvolutionaryStage.intelligence:
        descriptions.add(
          'An intelligent species has emerged, capable of abstract thought, tool use, and cultural transmission.',
        );
        if (habitability > 75) {
          descriptions.add(
            'They have developed complex social structures and may be on the path to technological civilization.',
          );
        } else {
          descriptions.add(
            'Despite environmental challenges, their intelligence allows them to adapt and thrive.',
          );
        }
        break;
    }

    // Add trait-based detail
    if (traits.isNotEmpty) {
      descriptions.add(
        'Notable adaptations include: ${traits.take(3).join(", ")}.',
      );
    }

    return descriptions.join(' ');
  }
}
