/// Atmospheric composition profile for a planet
class AtmosphericProfile {
  final Map<String, double> gasComposition; // Gas name -> percentage
  final double pressure; // in atmospheres (Earth = 1.0)
  final double density; // in kg/m³
  final String
  breathability; // 'Breathable', 'Marginally Breathable', 'Toxic', 'Lethal'
  final String dominantGas;
  final String atmosphereColor; // Hex color for visualization
  final List<String> characteristics;

  AtmosphericProfile({
    required this.gasComposition,
    required this.pressure,
    required this.density,
    required this.breathability,
    required this.dominantGas,
    required this.atmosphereColor,
    required this.characteristics,
  });

  /// Get breathability as a safety level (0-3)
  /// 0 = Breathable, 1 = Marginally, 2 = Toxic, 3 = Lethal
  int get safetyLevel {
    switch (breathability) {
      case 'Breathable':
        return 0;
      case 'Marginally Breathable':
        return 1;
      case 'Toxic':
        return 2;
      case 'Lethal':
        return 3;
      default:
        return 3;
    }
  }

  /// Get total gas percentage (should be ~100%)
  double get totalPercentage {
    return gasComposition.values.fold(0.0, (sum, val) => sum + val);
  }

  /// Get sorted list of gases by percentage (highest first)
  List<MapEntry<String, double>> get sortedGases {
    final entries = gasComposition.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get human-readable description
  String get description {
    final gases = sortedGases.take(3).map((e) => e.key).join(', ');
    return '$dominantGas-rich atmosphere with $gases. Pressure: ${pressure.toStringAsFixed(2)} atm.';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'gasComposition': gasComposition,
      'pressure': pressure,
      'density': density,
      'breathability': breathability,
      'dominantGas': dominantGas,
      'atmosphereColor': atmosphereColor,
      'characteristics': characteristics,
    };
  }

  /// Create from JSON
  factory AtmosphericProfile.fromJson(Map<String, dynamic> json) {
    return AtmosphericProfile(
      gasComposition: Map<String, double>.from(json['gasComposition']),
      pressure: json['pressure'] as double,
      density: json['density'] as double,
      breathability: json['breathability'] as String,
      dominantGas: json['dominantGas'] as String,
      atmosphereColor: json['atmosphereColor'] as String,
      characteristics: List<String>.from(json['characteristics']),
    );
  }

  @override
  String toString() {
    return 'AtmosphericProfile(dominant: $dominantGas, pressure: ${pressure}atm, breathability: $breathability)';
  }
}
