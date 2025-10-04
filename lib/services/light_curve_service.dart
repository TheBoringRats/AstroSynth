import 'dart:math';

import '../models/light_curve.dart';

/// Service for generating and analyzing light curves
///
/// Simulates realistic stellar brightness data with transits
/// for citizen science training and analysis
class LightCurveService {
  final Random _random = Random();

  /// Generate a realistic light curve with transits
  LightCurve generateLightCurve({
    required String starName,
    String? planetName,
    int dataPoints = 500,
    double observationDays = 30.0,
    int numberOfTransits = 2,
    bool addNoise = true,
    double transitDepth = 0.02, // 2% brightness drop
    double transitDuration = 3.0, // hours
  }) {
    final id = 'lc_${starName.replaceAll(' ', '_')}_${_random.nextInt(10000)}';
    final now = DateTime.now();

    // Generate base light curve points
    final points = <LightCurveDataPoint>[];
    final timeStep = observationDays / dataPoints;

    // Calculate transit positions
    final transits = <TransitEvent>[];
    final transitInterval = observationDays / (numberOfTransits + 1);

    for (int i = 0; i < numberOfTransits; i++) {
      final transitMidTime = (i + 1) * transitInterval;
      final transitStart = transitMidTime - transitDuration / 2;
      final transitEnd = transitMidTime + transitDuration / 2;

      transits.add(
        TransitEvent(
          startTime: transitStart,
          midTime: transitMidTime,
          endTime: transitEnd,
          depth: transitDepth,
          duration: transitDuration,
        ),
      );
    }

    // Generate data points
    for (int i = 0; i < dataPoints; i++) {
      final time = i * timeStep;
      double brightness = 1.0; // Baseline brightness

      // Add stellar variability (slight random variations)
      if (addNoise) {
        brightness += (_random.nextDouble() - 0.5) * 0.003; // ±0.3% variation
      }

      // Apply transit dimming
      for (final transit in transits) {
        if (time >= transit.startTime && time <= transit.endTime) {
          // Calculate transit depth at this time (parabolic shape)
          final transitProgress = (time - transit.startTime) / transit.duration;
          final dimming = _calculateTransitDimming(
            transitProgress,
            transit.depth,
          );
          brightness -= dimming;
        }
      }

      // Add measurement error
      final error = addNoise ? 0.001 + _random.nextDouble() * 0.001 : null;

      points.add(
        LightCurveDataPoint(
          time: time,
          brightness: brightness.clamp(0.0, 1.0),
          error: error,
        ),
      );
    }

    return LightCurve(
      id: id,
      starName: starName,
      planetName: planetName,
      dataPoints: points,
      observationDuration: observationDays,
      observationDate: now,
      instrument: _random.nextBool()
          ? 'Kepler Space Telescope'
          : 'TESS (Transiting Exoplanet Survey Satellite)',
      hasKnownPlanet: planetName != null,
      knownTransits: planetName != null ? transits : null,
    );
  }

  /// Calculate transit dimming at a specific progress point
  /// Uses a parabolic transit model for realistic shape
  double _calculateTransitDimming(double progress, double maxDepth) {
    // Progress is 0.0 at start, 0.5 at midpoint, 1.0 at end
    // Create smooth ingress, flat bottom, smooth egress

    if (progress < 0.2) {
      // Ingress (entering)
      final ingressProgress = progress / 0.2;
      return maxDepth * ingressProgress * ingressProgress;
    } else if (progress < 0.8) {
      // Flat bottom
      return maxDepth;
    } else {
      // Egress (exiting)
      final egressProgress = (1.0 - progress) / 0.2;
      return maxDepth * egressProgress * egressProgress;
    }
  }

  /// Generate a collection of light curves for user practice
  List<LightCurve> generateTrainingSet({int count = 10}) {
    final curves = <LightCurve>[];
    final starNames = [
      'Kepler-442',
      'TRAPPIST-1',
      'Proxima Centauri',
      'Kepler-186',
      'Kepler-452',
      'HD 40307',
      'Gliese 667 C',
      'Kepler-62',
      'Kepler-69',
      'HD 85512',
    ];

    for (int i = 0; i < count; i++) {
      final starName = starNames[i % starNames.length];
      final hasPlanet = i % 3 != 0; // 2/3 have planets

      // Vary difficulty
      final double depth;
      final int transits;

      if (i < 3) {
        // Easy
        depth = 0.02 + _random.nextDouble() * 0.01; // 2-3% drop
        transits = 2;
      } else if (i < 6) {
        // Medium
        depth = 0.01 + _random.nextDouble() * 0.01; // 1-2% drop
        transits = 2;
      } else {
        // Hard
        depth = 0.005 + _random.nextDouble() * 0.005; // 0.5-1% drop
        transits = 1;
      }

      curves.add(
        generateLightCurve(
          starName: starName,
          planetName: hasPlanet ? '$starName b' : null,
          dataPoints: 500,
          observationDays: 30.0,
          numberOfTransits: hasPlanet ? transits : 0,
          transitDepth: depth,
          transitDuration: 2.0 + _random.nextDouble() * 2.0, // 2-4 hours
        ),
      );
    }

    return curves;
  }

  /// Validate a user observation against known transits
  UserObservation validateObservation(
    UserObservation observation,
    LightCurve lightCurve,
  ) {
    if (!lightCurve.hasKnownPlanet ||
        lightCurve.knownTransits == null ||
        lightCurve.knownTransits!.isEmpty) {
      // Can't validate if there's no ground truth
      return observation;
    }

    // Find the closest matching transit
    TransitEvent? closestTransit;
    double closestDistance = double.infinity;

    for (final transit in lightCurve.knownTransits!) {
      final distance = (transit.midTime - observation.midTime).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestTransit = transit;
      }
    }

    if (closestTransit == null) {
      return observation.withValidation(isCorrect: false, accuracy: 0.0);
    }

    // Calculate accuracy based on overlap
    final accuracy = _calculateAccuracy(observation, closestTransit);
    final isCorrect = accuracy > 0.5; // 50% overlap threshold

    return observation.withValidation(isCorrect: isCorrect, accuracy: accuracy);
  }

  /// Calculate accuracy of observation vs actual transit
  double _calculateAccuracy(UserObservation obs, TransitEvent transit) {
    // Calculate overlap between marked region and actual transit
    final overlapStart = max(obs.startTime, transit.startTime);
    final overlapEnd = min(obs.endTime, transit.endTime);

    if (overlapStart >= overlapEnd) {
      return 0.0; // No overlap
    }

    final overlapDuration = overlapEnd - overlapStart;
    final unionStart = min(obs.startTime, transit.startTime);
    final unionEnd = max(obs.endTime, transit.endTime);
    final unionDuration = unionEnd - unionStart;

    // Jaccard similarity (intersection over union)
    return overlapDuration / unionDuration;
  }

  /// Check if observation deserves any achievements
  List<ScienceAchievement> checkAchievements(
    CitizenScienceStats stats,
    UserObservation newObservation,
  ) {
    final newAchievements = <ScienceAchievement>[];
    final allAchievements = ScienceAchievement.getAllAchievements();

    for (final achievement in allAchievements) {
      // Skip if already unlocked
      if (stats.unlockedAchievements.contains(achievement.id)) {
        continue;
      }

      bool unlocked = false;

      switch (achievement.type) {
        case AchievementType.observation:
          unlocked = stats.totalObservations >= achievement.requiredCount;
          break;

        case AchievementType.accuracy:
          unlocked =
              stats.correctObservations >= achievement.requiredCount &&
              stats.averageAccuracy >= 0.9;
          break;

        case AchievementType.discovery:
          unlocked = stats.transitsDiscovered >= achievement.requiredCount;
          break;

        case AchievementType.contribution:
          unlocked = stats.lightCurvesAnalyzed >= achievement.requiredCount;
          break;

        case AchievementType.validation:
          unlocked = stats.validationsPerformed >= achievement.requiredCount;
          break;
      }

      if (unlocked) {
        newAchievements.add(achievement);
      }
    }

    return newAchievements;
  }

  /// Update user statistics with new observation
  CitizenScienceStats updateStats(
    CitizenScienceStats oldStats,
    UserObservation observation,
  ) {
    final newUnlocked = List<String>.from(oldStats.unlockedAchievements);
    final newAchievements = checkAchievements(oldStats, observation);

    int pointsGained = 10; // Base points for observation

    for (final achievement in newAchievements) {
      if (!newUnlocked.contains(achievement.id)) {
        newUnlocked.add(achievement.id);
        pointsGained += achievement.pointValue;
      }
    }

    // Bonus points for accuracy
    if (observation.isCorrect == true) {
      pointsGained += (observation.accuracy! * 10).round();
    }

    final newTotal = oldStats.totalObservations + 1;
    final newCorrect =
        oldStats.correctObservations + (observation.isCorrect == true ? 1 : 0);

    // Recalculate average accuracy
    final newAvgAccuracy = newTotal > 0 ? (newCorrect / newTotal) : 0.0;

    return CitizenScienceStats(
      userId: oldStats.userId,
      totalObservations: newTotal,
      correctObservations: newCorrect,
      lightCurvesAnalyzed: oldStats.lightCurvesAnalyzed + 1,
      transitsDiscovered:
          oldStats.transitsDiscovered + (observation.isCorrect == true ? 1 : 0),
      validationsPerformed: oldStats.validationsPerformed,
      averageAccuracy: newAvgAccuracy,
      totalPoints: oldStats.totalPoints + pointsGained,
      unlockedAchievements: newUnlocked,
      firstContribution: oldStats.firstContribution,
      lastContribution: DateTime.now(),
    );
  }

  /// Get a leaderboard entry summary
  Map<String, dynamic> getLeaderboardEntry(CitizenScienceStats stats) {
    return {
      'userId': stats.userId,
      'totalPoints': stats.totalPoints,
      'level': stats.level,
      'rank': stats.rank,
      'transitsDiscovered': stats.transitsDiscovered,
      'accuracyPercentage': stats.accuracyPercentage.toStringAsFixed(1),
      'totalObservations': stats.totalObservations,
    };
  }

  /// Generate a tutorial light curve (very easy, clear transit)
  LightCurve generateTutorialCurve() {
    return generateLightCurve(
      starName: 'Tutorial Star',
      planetName: 'Tutorial Planet b',
      dataPoints: 300,
      observationDays: 20.0,
      numberOfTransits: 2,
      transitDepth: 0.03, // Very obvious 3% drop
      transitDuration: 4.0, // Long duration
      addNoise: false, // Clean data
    );
  }

  /// Export observations to CSV format (for advanced users)
  String exportToCsv(
    LightCurve lightCurve,
    List<UserObservation> observations,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Light Curve: ${lightCurve.starName}');
    buffer.writeln('# Star: ${lightCurve.starName}');
    if (lightCurve.planetName != null) {
      buffer.writeln('# Planet: ${lightCurve.planetName}');
    }
    buffer.writeln(
      '# Observation Date: ${lightCurve.observationDate.toIso8601String()}',
    );
    buffer.writeln('# Instrument: ${lightCurve.instrument}');
    buffer.writeln('#');
    buffer.writeln('Time (days),Brightness,Error');

    // Data points
    for (final point in lightCurve.dataPoints) {
      buffer.write('${point.time.toStringAsFixed(6)},');
      buffer.write('${point.brightness.toStringAsFixed(6)}');
      if (point.error != null) {
        buffer.write(',${point.error!.toStringAsFixed(6)}');
      }
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('# User Observations');
    buffer.writeln('Start Time,End Time,Confidence,Correct,Accuracy');

    for (final obs in observations) {
      buffer.write('${obs.startTime.toStringAsFixed(4)},');
      buffer.write('${obs.endTime.toStringAsFixed(4)},');
      buffer.write('${obs.confidence.toStringAsFixed(2)},');
      buffer.write('${obs.isCorrect ?? "unknown"},');
      buffer.writeln('${obs.accuracy?.toStringAsFixed(3) ?? "N/A"}');
    }

    return buffer.toString();
  }
}
