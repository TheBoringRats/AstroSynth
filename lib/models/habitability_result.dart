/// Represents the result of habitability analysis
class HabitabilityResult {
  final double temperatureScore;
  final double sizeScore;
  final double starScore;
  final double orbitScore;
  final double overallScore;

  final String temperatureAnalysis;
  final String sizeAnalysis;
  final String starAnalysis;
  final String orbitAnalysis;
  final String overallAnalysis;

  final bool isHabitable;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;

  HabitabilityResult({
    required this.temperatureScore,
    required this.sizeScore,
    required this.starScore,
    required this.orbitScore,
    required this.overallScore,
    required this.temperatureAnalysis,
    required this.sizeAnalysis,
    required this.starAnalysis,
    required this.orbitAnalysis,
    required this.overallAnalysis,
    required this.isHabitable,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
  });

  /// Get habitability category as a string
  String get category {
    if (overallScore >= 70) return 'Highly Habitable';
    if (overallScore >= 50) return 'Potentially Habitable';
    if (overallScore >= 30) return 'Marginally Habitable';
    return 'Unlikely Habitable';
  }

  /// Get color based on habitability score
  String get colorCode {
    if (overallScore >= 70) return '#00B894'; // Green
    if (overallScore >= 50) return '#FDCB6E'; // Yellow
    if (overallScore >= 30) return '#FD79A8'; // Pink
    return '#FF7675'; // Red
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureScore': temperatureScore,
      'sizeScore': sizeScore,
      'starScore': starScore,
      'orbitScore': orbitScore,
      'overallScore': overallScore,
      'temperatureAnalysis': temperatureAnalysis,
      'sizeAnalysis': sizeAnalysis,
      'starAnalysis': starAnalysis,
      'orbitAnalysis': orbitAnalysis,
      'overallAnalysis': overallAnalysis,
      'isHabitable': isHabitable,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
    };
  }

  factory HabitabilityResult.fromJson(Map<String, dynamic> json) {
    return HabitabilityResult(
      temperatureScore: json['temperatureScore'] as double,
      sizeScore: json['sizeScore'] as double,
      starScore: json['starScore'] as double,
      orbitScore: json['orbitScore'] as double,
      overallScore: json['overallScore'] as double,
      temperatureAnalysis: json['temperatureAnalysis'] as String,
      sizeAnalysis: json['sizeAnalysis'] as String,
      starAnalysis: json['starAnalysis'] as String,
      orbitAnalysis: json['orbitAnalysis'] as String,
      overallAnalysis: json['overallAnalysis'] as String,
      isHabitable: json['isHabitable'] as bool,
      strengths: List<String>.from(json['strengths'] as List),
      weaknesses: List<String>.from(json['weaknesses'] as List),
      recommendations: List<String>.from(json['recommendations'] as List),
    );
  }

  @override
  String toString() {
    return 'HabitabilityResult(overall: $overallScore, category: $category)';
  }
}
