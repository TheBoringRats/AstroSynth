import 'dart:ui';

/// Enhanced habitability result with 8 scientific factors
class EnhancedHabitabilityResult {
  // Core 4 factors (existing)
  final double temperatureScore;
  final double sizeScore;
  final double starScore;
  final double orbitScore;

  // New 4 factors
  final double magneticFieldScore;
  final double plateTectonicsScore;
  final double moonPresenceScore;
  final double eccentricityScore;

  // Overall score
  final double overallScore;

  // Analysis for each factor
  final String temperatureAnalysis;
  final String sizeAnalysis;
  final String starAnalysis;
  final String orbitAnalysis;
  final String magneticFieldAnalysis;
  final String plateTectonicsAnalysis;
  final String moonPresenceAnalysis;
  final String eccentricityAnalysis;
  final String overallAnalysis;

  // Habitability assessment
  final bool isHabitable;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  EnhancedHabitabilityResult({
    required this.temperatureScore,
    required this.sizeScore,
    required this.starScore,
    required this.orbitScore,
    required this.magneticFieldScore,
    required this.plateTectonicsScore,
    required this.moonPresenceScore,
    required this.eccentricityScore,
    required this.overallScore,
    required this.temperatureAnalysis,
    required this.sizeAnalysis,
    required this.starAnalysis,
    required this.orbitAnalysis,
    required this.magneticFieldAnalysis,
    required this.plateTectonicsAnalysis,
    required this.moonPresenceAnalysis,
    required this.eccentricityAnalysis,
    required this.overallAnalysis,
    required this.isHabitable,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  /// Get habitability category
  String get category {
    if (overallScore >= 75) return 'Highly Habitable';
    if (overallScore >= 60) return 'Very Habitable';
    if (overallScore >= 45) return 'Potentially Habitable';
    if (overallScore >= 30) return 'Marginally Habitable';
    return 'Unlikely Habitable';
  }

  /// Get color based on habitability score
  Color get color {
    if (overallScore >= 75) return const Color(0xFF00B894); // Bright green
    if (overallScore >= 60) return const Color(0xFF55EFC4); // Light green
    if (overallScore >= 45) return const Color(0xFFFDCB6E); // Yellow
    if (overallScore >= 30) return const Color(0xFFFFA07A); // Light orange
    return const Color(0xFFFF7675); // Red
  }

  /// Get all factor scores as a map (for spider chart)
  Map<String, double> get factorScores => {
    'Temperature': temperatureScore,
    'Size': sizeScore,
    'Star Type': starScore,
    'Orbit': orbitScore,
    'Magnetic Field': magneticFieldScore,
    'Plate Tectonics': plateTectonicsScore,
    'Moon': moonPresenceScore,
    'Eccentricity': eccentricityScore,
  };

  /// Get factor analyses as a map
  Map<String, String> get factorAnalyses => {
    'Temperature': temperatureAnalysis,
    'Size': sizeAnalysis,
    'Star Type': starAnalysis,
    'Orbit': orbitAnalysis,
    'Magnetic Field': magneticFieldAnalysis,
    'Plate Tectonics': plateTectonicsAnalysis,
    'Moon': moonPresenceAnalysis,
    'Eccentricity': eccentricityAnalysis,
  };

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'temperatureScore': temperatureScore,
      'sizeScore': sizeScore,
      'starScore': starScore,
      'orbitScore': orbitScore,
      'magneticFieldScore': magneticFieldScore,
      'plateTectonicsScore': plateTectonicsScore,
      'moonPresenceScore': moonPresenceScore,
      'eccentricityScore': eccentricityScore,
      'overallScore': overallScore,
      'temperatureAnalysis': temperatureAnalysis,
      'sizeAnalysis': sizeAnalysis,
      'starAnalysis': starAnalysis,
      'orbitAnalysis': orbitAnalysis,
      'magneticFieldAnalysis': magneticFieldAnalysis,
      'plateTectonicsAnalysis': plateTectonicsAnalysis,
      'moonPresenceAnalysis': moonPresenceAnalysis,
      'eccentricityAnalysis': eccentricityAnalysis,
      'overallAnalysis': overallAnalysis,
      'isHabitable': isHabitable,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
    };
  }

  /// Create from JSON
  factory EnhancedHabitabilityResult.fromJson(Map<String, dynamic> json) {
    return EnhancedHabitabilityResult(
      temperatureScore: json['temperatureScore'] as double,
      sizeScore: json['sizeScore'] as double,
      starScore: json['starScore'] as double,
      orbitScore: json['orbitScore'] as double,
      magneticFieldScore: json['magneticFieldScore'] as double,
      plateTectonicsScore: json['plateTectonicsScore'] as double,
      moonPresenceScore: json['moonPresenceScore'] as double,
      eccentricityScore: json['eccentricityScore'] as double,
      overallScore: json['overallScore'] as double,
      temperatureAnalysis: json['temperatureAnalysis'] as String,
      sizeAnalysis: json['sizeAnalysis'] as String,
      starAnalysis: json['starAnalysis'] as String,
      orbitAnalysis: json['orbitAnalysis'] as String,
      magneticFieldAnalysis: json['magneticFieldAnalysis'] as String,
      plateTectonicsAnalysis: json['plateTectonicsAnalysis'] as String,
      moonPresenceAnalysis: json['moonPresenceAnalysis'] as String,
      eccentricityAnalysis: json['eccentricityAnalysis'] as String,
      overallAnalysis: json['overallAnalysis'] as String,
      isHabitable: json['isHabitable'] as bool,
      strengths: List<String>.from(json['strengths'] as List),
      weaknesses: List<String>.from(json['weaknesses'] as List),
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }

  @override
  String toString() {
    return 'EnhancedHabitabilityResult(overall: $overallScore%, category: $category)';
  }
}
