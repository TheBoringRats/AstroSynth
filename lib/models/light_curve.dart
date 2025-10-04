/// Models for Citizen Science light curve analysis
///
/// Enables users to identify exoplanet transits by analyzing
/// brightness variations in stellar light curves

import 'package:flutter/material.dart';

/// Represents a single data point in a light curve
class LightCurveDataPoint {
  final double time; // Time in hours or days
  final double brightness; // Normalized brightness (0.0-1.0)
  final double? error; // Measurement uncertainty

  const LightCurveDataPoint({
    required this.time,
    required this.brightness,
    this.error,
  });

  /// Create from JSON
  factory LightCurveDataPoint.fromJson(Map<String, dynamic> json) {
    return LightCurveDataPoint(
      time: (json['time'] as num).toDouble(),
      brightness: (json['brightness'] as num).toDouble(),
      error: json['error'] != null ? (json['error'] as num).toDouble() : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'brightness': brightness,
      if (error != null) 'error': error,
    };
  }
}

/// Represents a complete light curve dataset
class LightCurve {
  final String id;
  final String starName;
  final String? planetName; // If already confirmed
  final List<LightCurveDataPoint> dataPoints;
  final double observationDuration; // Total duration in days
  final DateTime observationDate;
  final String instrument; // Telescope/instrument name
  final bool hasKnownPlanet; // True if this is a confirmed planet
  final List<TransitEvent>? knownTransits; // Ground truth for validation

  const LightCurve({
    required this.id,
    required this.starName,
    this.planetName,
    required this.dataPoints,
    required this.observationDuration,
    required this.observationDate,
    required this.instrument,
    this.hasKnownPlanet = false,
    this.knownTransits,
  });

  /// Get time range
  double get minTime => dataPoints.isEmpty ? 0 : dataPoints.first.time;
  double get maxTime => dataPoints.isEmpty ? 0 : dataPoints.last.time;

  /// Get brightness range
  double get minBrightness {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((p) => p.brightness).reduce((a, b) => a < b ? a : b);
  }

  double get maxBrightness {
    if (dataPoints.isEmpty) return 1;
    return dataPoints.map((p) => p.brightness).reduce((a, b) => a > b ? a : b);
  }

  /// Calculate baseline brightness (median)
  double get baselineBrightness {
    if (dataPoints.isEmpty) return 1.0;
    final sorted = dataPoints.map((p) => p.brightness).toList()..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// Get difficulty level based on transit depth
  String get difficultyLevel {
    if (!hasKnownPlanet || knownTransits == null || knownTransits!.isEmpty) {
      return 'Unknown';
    }
    final depth = knownTransits!.first.depth;
    if (depth > 0.02) return 'Easy';
    if (depth > 0.01) return 'Medium';
    if (depth > 0.005) return 'Hard';
    return 'Expert';
  }

  /// Create from JSON
  factory LightCurve.fromJson(Map<String, dynamic> json) {
    return LightCurve(
      id: json['id'] as String,
      starName: json['starName'] as String,
      planetName: json['planetName'] as String?,
      dataPoints: (json['dataPoints'] as List)
          .map((p) => LightCurveDataPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      observationDuration: (json['observationDuration'] as num).toDouble(),
      observationDate: DateTime.parse(json['observationDate'] as String),
      instrument: json['instrument'] as String,
      hasKnownPlanet: json['hasKnownPlanet'] as bool? ?? false,
      knownTransits: json['knownTransits'] != null
          ? (json['knownTransits'] as List)
                .map((t) => TransitEvent.fromJson(t as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'starName': starName,
      if (planetName != null) 'planetName': planetName,
      'dataPoints': dataPoints.map((p) => p.toJson()).toList(),
      'observationDuration': observationDuration,
      'observationDate': observationDate.toIso8601String(),
      'instrument': instrument,
      'hasKnownPlanet': hasKnownPlanet,
      if (knownTransits != null)
        'knownTransits': knownTransits!.map((t) => t.toJson()).toList(),
    };
  }
}

/// Represents a transit event (planet passing in front of star)
class TransitEvent {
  final double startTime; // When transit begins
  final double midTime; // When transit is at maximum
  final double endTime; // When transit ends
  final double depth; // How much brightness drops (0.0-1.0)
  final double duration; // Transit duration in hours

  const TransitEvent({
    required this.startTime,
    required this.midTime,
    required this.endTime,
    required this.depth,
    required this.duration,
  });

  /// Check if a time is within this transit
  bool containsTime(double time) {
    return time >= startTime && time <= endTime;
  }

  /// Create from JSON
  factory TransitEvent.fromJson(Map<String, dynamic> json) {
    return TransitEvent(
      startTime: (json['startTime'] as num).toDouble(),
      midTime: (json['midTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'midTime': midTime,
      'endTime': endTime,
      'depth': depth,
      'duration': duration,
    };
  }
}

/// Represents a user's observation/marking of a potential transit
class UserObservation {
  final String id;
  final String lightCurveId;
  final String userId;
  final double startTime;
  final double endTime;
  final DateTime timestamp;
  final double confidence; // User's confidence level (0.0-1.0)
  final String? notes;

  // Validation results (compared to ground truth)
  final bool? isCorrect;
  final double? accuracy; // How close to actual transit (0.0-1.0)

  const UserObservation({
    required this.id,
    required this.lightCurveId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.timestamp,
    this.confidence = 0.5,
    this.notes,
    this.isCorrect,
    this.accuracy,
  });

  /// Duration of marked transit
  double get duration => endTime - startTime;

  /// Midpoint of marked transit
  double get midTime => (startTime + endTime) / 2;

  /// Copy with validation results
  UserObservation withValidation({
    required bool isCorrect,
    required double accuracy,
  }) {
    return UserObservation(
      id: id,
      lightCurveId: lightCurveId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      timestamp: timestamp,
      confidence: confidence,
      notes: notes,
      isCorrect: isCorrect,
      accuracy: accuracy,
    );
  }

  /// Create from JSON
  factory UserObservation.fromJson(Map<String, dynamic> json) {
    return UserObservation(
      id: json['id'] as String,
      lightCurveId: json['lightCurveId'] as String,
      userId: json['userId'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : 0.5,
      notes: json['notes'] as String?,
      isCorrect: json['isCorrect'] as bool?,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lightCurveId': lightCurveId,
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      if (notes != null) 'notes': notes,
      if (isCorrect != null) 'isCorrect': isCorrect,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }
}

/// Achievement/Badge for citizen science contributions
class ScienceAchievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int pointValue;
  final AchievementType type;
  final int requiredCount; // How many actions needed

  const ScienceAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.pointValue,
    required this.type,
    required this.requiredCount,
  });

  /// Predefined achievements
  static ScienceAchievement firstObservation() {
    return const ScienceAchievement(
      id: 'first_observation',
      name: 'First Light',
      description: 'Mark your first transit event',
      icon: Icons.light_mode,
      color: Color(0xFFFFD700),
      pointValue: 10,
      type: AchievementType.observation,
      requiredCount: 1,
    );
  }

  static ScienceAchievement accurateObserver() {
    return const ScienceAchievement(
      id: 'accurate_observer',
      name: 'Keen Eye',
      description: 'Achieve 90%+ accuracy on 5 observations',
      icon: Icons.visibility,
      color: Color(0xFF00D2FF),
      pointValue: 50,
      type: AchievementType.accuracy,
      requiredCount: 5,
    );
  }

  static ScienceAchievement transitHunter() {
    return const ScienceAchievement(
      id: 'transit_hunter',
      name: 'Transit Hunter',
      description: 'Successfully identify 10 transit events',
      icon: Icons.search,
      color: Color(0xFFFF6B6B),
      pointValue: 100,
      type: AchievementType.discovery,
      requiredCount: 10,
    );
  }

  static ScienceAchievement expertAnalyst() {
    return const ScienceAchievement(
      id: 'expert_analyst',
      name: 'Expert Analyst',
      description: 'Complete 50 light curve analyses',
      icon: Icons.star,
      color: Color(0xFFB76CFD),
      pointValue: 250,
      type: AchievementType.contribution,
      requiredCount: 50,
    );
  }

  static ScienceAchievement communityValidator() {
    return const ScienceAchievement(
      id: 'community_validator',
      name: 'Community Validator',
      description: 'Help validate 25 community observations',
      icon: Icons.verified,
      color: Color(0xFF4CAF50),
      pointValue: 150,
      type: AchievementType.validation,
      requiredCount: 25,
    );
  }

  /// Get all achievements
  static List<ScienceAchievement> getAllAchievements() {
    return [
      firstObservation(),
      accurateObserver(),
      transitHunter(),
      expertAnalyst(),
      communityValidator(),
    ];
  }
}

/// Types of achievements
enum AchievementType {
  observation,
  accuracy,
  discovery,
  contribution,
  validation,
}

/// User's citizen science statistics
class CitizenScienceStats {
  final String userId;
  final int totalObservations;
  final int correctObservations;
  final int lightCurvesAnalyzed;
  final int transitsDiscovered;
  final int validationsPerformed;
  final double averageAccuracy;
  final int totalPoints;
  final List<String> unlockedAchievements;
  final DateTime firstContribution;
  final DateTime lastContribution;

  const CitizenScienceStats({
    required this.userId,
    required this.totalObservations,
    required this.correctObservations,
    required this.lightCurvesAnalyzed,
    required this.transitsDiscovered,
    required this.validationsPerformed,
    required this.averageAccuracy,
    required this.totalPoints,
    required this.unlockedAchievements,
    required this.firstContribution,
    required this.lastContribution,
  });

  /// Calculate accuracy percentage
  double get accuracyPercentage {
    if (totalObservations == 0) return 0;
    return (correctObservations / totalObservations) * 100;
  }

  /// Get user level based on points
  int get level => (totalPoints / 100).floor() + 1;

  /// Points needed for next level
  int get pointsToNextLevel => (level * 100) - totalPoints;

  /// Get rank based on points
  String get rank {
    if (totalPoints < 50) return 'Novice';
    if (totalPoints < 150) return 'Observer';
    if (totalPoints < 300) return 'Analyst';
    if (totalPoints < 500) return 'Expert';
    if (totalPoints < 1000) return 'Master';
    return 'Legend';
  }

  /// Create empty stats
  factory CitizenScienceStats.empty(String userId) {
    final now = DateTime.now();
    return CitizenScienceStats(
      userId: userId,
      totalObservations: 0,
      correctObservations: 0,
      lightCurvesAnalyzed: 0,
      transitsDiscovered: 0,
      validationsPerformed: 0,
      averageAccuracy: 0,
      totalPoints: 0,
      unlockedAchievements: [],
      firstContribution: now,
      lastContribution: now,
    );
  }

  /// Create from JSON
  factory CitizenScienceStats.fromJson(Map<String, dynamic> json) {
    return CitizenScienceStats(
      userId: json['userId'] as String,
      totalObservations: json['totalObservations'] as int,
      correctObservations: json['correctObservations'] as int,
      lightCurvesAnalyzed: json['lightCurvesAnalyzed'] as int,
      transitsDiscovered: json['transitsDiscovered'] as int,
      validationsPerformed: json['validationsPerformed'] as int,
      averageAccuracy: (json['averageAccuracy'] as num).toDouble(),
      totalPoints: json['totalPoints'] as int,
      unlockedAchievements: List<String>.from(
        json['unlockedAchievements'] as List,
      ),
      firstContribution: DateTime.parse(json['firstContribution'] as String),
      lastContribution: DateTime.parse(json['lastContribution'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalObservations': totalObservations,
      'correctObservations': correctObservations,
      'lightCurvesAnalyzed': lightCurvesAnalyzed,
      'transitsDiscovered': transitsDiscovered,
      'validationsPerformed': validationsPerformed,
      'averageAccuracy': averageAccuracy,
      'totalPoints': totalPoints,
      'unlockedAchievements': unlockedAchievements,
      'firstContribution': firstContribution.toIso8601String(),
      'lastContribution': lastContribution.toIso8601String(),
    };
  }
}
