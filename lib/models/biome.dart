/// Represents a biome classification for a planet
class Biome {
  final String type;
  final String description;
  final List<String> characteristics;
  final String imageUrl;
  final double temperature; // Average temperature in Kelvin
  final String atmosphereComposition;
  final bool supportsLife;

  Biome({
    required this.type,
    required this.description,
    required this.characteristics,
    required this.imageUrl,
    required this.temperature,
    required this.atmosphereComposition,
    required this.supportsLife,
  });

  /// Predefined biome types
  static Biome desert() {
    return Biome(
      type: 'Desert',
      description: 'Hot and dry planet with minimal water content',
      characteristics: [
        'High surface temperature',
        'Minimal atmospheric water',
        'Rocky or sandy surface',
        'Extreme day-night temperature variation',
      ],
      imageUrl: 'assets/images/biome_desert.png',
      temperature: 350.0,
      atmosphereComposition: 'Thin CO2/N2',
      supportsLife: false,
    );
  }

  static Biome ocean() {
    return Biome(
      type: 'Ocean',
      description: 'Water-covered planet with deep oceans',
      characteristics: [
        'Extensive water coverage',
        'Moderate temperature',
        'Thick humid atmosphere',
        'Potential for aquatic life',
      ],
      imageUrl: 'assets/images/biome_ocean.png',
      temperature: 290.0,
      atmosphereComposition: 'N2/O2 with water vapor',
      supportsLife: true,
    );
  }

  static Biome ice() {
    return Biome(
      type: 'Ice',
      description: 'Frozen planet with ice-covered surface',
      characteristics: [
        'Extremely cold temperature',
        'Frozen water surface',
        'Thin atmosphere',
        'Possible subsurface ocean',
      ],
      imageUrl: 'assets/images/biome_ice.png',
      temperature: 200.0,
      atmosphereComposition: 'Thin N2/CO2',
      supportsLife: false,
    );
  }

  static Biome volcanic() {
    return Biome(
      type: 'Volcanic',
      description: 'Geologically active with volcanic features',
      characteristics: [
        'High volcanic activity',
        'Thick toxic atmosphere',
        'Extreme heat',
        'Sulfuric compounds',
      ],
      imageUrl: 'assets/images/biome_volcanic.png',
      temperature: 700.0,
      atmosphereComposition: 'CO2/SO2',
      supportsLife: false,
    );
  }

  static Biome tropical() {
    return Biome(
      type: 'Tropical',
      description: 'Warm and humid with abundant vegetation',
      characteristics: [
        'Warm temperature',
        'High humidity',
        'Dense atmosphere',
        'Potential for complex life',
      ],
      imageUrl: 'assets/images/biome_tropical.png',
      temperature: 300.0,
      atmosphereComposition: 'N2/O2 with high H2O',
      supportsLife: true,
    );
  }

  static Biome temperate() {
    return Biome(
      type: 'Temperate',
      description: 'Earth-like conditions with moderate climate',
      characteristics: [
        'Moderate temperature',
        'Seasonal variations',
        'Balanced atmosphere',
        'High potential for life',
      ],
      imageUrl: 'assets/images/biome_temperate.png',
      temperature: 288.0,
      atmosphereComposition: 'N2/O2',
      supportsLife: true,
    );
  }

  static Biome tundra() {
    return Biome(
      type: 'Tundra',
      description: 'Cold planet with minimal vegetation',
      characteristics: [
        'Cold temperature',
        'Thin atmosphere',
        'Frozen ground',
        'Limited water availability',
      ],
      imageUrl: 'assets/images/biome_tundra.png',
      temperature: 250.0,
      atmosphereComposition: 'N2 dominant',
      supportsLife: false,
    );
  }

  static Biome barren() {
    return Biome(
      type: 'Barren',
      description: 'Lifeless rocky planet with no atmosphere',
      characteristics: [
        'No atmosphere',
        'Extreme temperature variations',
        'Rocky surface',
        'No water',
      ],
      imageUrl: 'assets/images/biome_barren.png',
      temperature: 400.0,
      atmosphereComposition: 'None',
      supportsLife: false,
    );
  }

  static Biome gasGiant() {
    return Biome(
      type: 'Gas Giant',
      description: 'Large planet composed primarily of gases',
      characteristics: [
        'No solid surface',
        'Thick gaseous atmosphere',
        'Strong winds',
        'Multiple moons possible',
      ],
      imageUrl: 'assets/images/biome_gas_giant.png',
      temperature: 150.0,
      atmosphereComposition: 'H2/He',
      supportsLife: false,
    );
  }

  static Biome rocky() {
    return Biome(
      type: 'Rocky',
      description: 'Small terrestrial planet with rocky surface',
      characteristics: [
        'Dense rocky composition',
        'Variable atmosphere',
        'Impact craters',
        'Possible volcanism',
      ],
      imageUrl: 'assets/images/biome_rocky.png',
      temperature: 320.0,
      atmosphereComposition: 'Variable',
      supportsLife: false,
    );
  }

  /// Classify biome based on planet properties
  static Biome classify({
    required double? temperature,
    required double? radius,
    required double? mass,
  }) {
    // Gas Giant check (large radius and mass)
    if (radius != null && radius > 4.0) {
      return gasGiant();
    }

    // Temperature-based classification
    if (temperature == null) {
      return barren(); // Unknown temperature defaults to barren
    }

    if (temperature > 500) {
      return volcanic();
    } else if (temperature > 320) {
      return desert();
    } else if (temperature > 290 && temperature <= 320) {
      return tropical();
    } else if (temperature >= 273 && temperature <= 290) {
      // Check for water world vs temperate
      if (radius != null && radius > 1.5 && radius <= 3.0) {
        return ocean();
      }
      return temperate();
    } else if (temperature >= 220 && temperature < 273) {
      return tundra();
    } else if (temperature < 220) {
      return ice();
    }

    return rocky(); // Default
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'characteristics': characteristics,
      'imageUrl': imageUrl,
      'temperature': temperature,
      'atmosphereComposition': atmosphereComposition,
      'supportsLife': supportsLife,
    };
  }

  factory Biome.fromJson(Map<String, dynamic> json) {
    return Biome(
      type: json['type'] as String,
      description: json['description'] as String,
      characteristics: List<String>.from(json['characteristics'] as List),
      imageUrl: json['imageUrl'] as String,
      temperature: json['temperature'] as double,
      atmosphereComposition: json['atmosphereComposition'] as String,
      supportsLife: json['supportsLife'] as bool,
    );
  }

  @override
  String toString() =>
      'Biome(type: $type, temp: $temperature K, life: $supportsLife)';
}
