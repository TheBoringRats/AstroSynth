import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/planet.dart';
import '../services/database_helper.dart';
import '../services/habitability_calculator.dart';
import '../services/nasa_api_service.dart';

/// Repository pattern for managing planet data
/// Handles coordination between API and local database
class PlanetRepository {
  final NASAApiService _apiService = NASAApiService();
  DatabaseHelper? _dbHelper;
  final HabitabilityCalculator _calculator = HabitabilityCalculator();

  // In-memory cache for web platform
  List<Planet> _cachedPlanets = [];
  DateTime? _lastCacheTime;

  PlanetRepository() {
    // Only use database on non-web platforms
    if (!kIsWeb) {
      _dbHelper = DatabaseHelper.instance;
    }
  }

  /// Get planets with caching strategy
  /// 1. Check if cache is stale
  /// 2. If stale or empty, fetch from API
  /// 3. Calculate habitability scores
  /// 4. Save to database (if not web)
  /// 5. Return planets
  Future<List<Planet>> getPlanets({
    bool forceRefresh = false,
    int limit = 50,
  }) async {
    // Web platform - use in-memory cache
    if (kIsWeb) {
      if (!forceRefresh && _cachedPlanets.isNotEmpty) {
        final cacheAge = _lastCacheTime != null
            ? DateTime.now().difference(_lastCacheTime!).inHours
            : 25;
        if (cacheAge < 24) {
          print('Returning ${_cachedPlanets.length} planets from memory cache');
          return _cachedPlanets;
        }
      }

      print('Fetching planets from NASA API...');
      final planets = await _apiService.fetchPlanets(limit: limit);
      final planetsWithScores = await _calculateScoresForPlanets(planets);

      _cachedPlanets = planetsWithScores;
      _lastCacheTime = DateTime.now();
      return planetsWithScores;
    }

    // Native platforms - use database
    if (!forceRefresh) {
      final isStale = await _dbHelper!.isCacheStale();
      if (!isStale) {
        final cachedPlanets = await _dbHelper!.getAllPlanets();
        if (cachedPlanets.isNotEmpty) {
          print('Returning ${cachedPlanets.length} planets from database');
          return cachedPlanets;
        }
      }
    }

    print('Fetching planets from NASA API...');
    final planets = await _apiService.fetchPlanets(limit: limit);
    final planetsWithScores = await _calculateScoresForPlanets(planets);
    await _dbHelper!.insertPlanets(planetsWithScores);

    return planetsWithScores;
  }

  /// Get habitable planets
  Future<List<Planet>> getHabitablePlanets({
    bool forceRefresh = false,
    double threshold = 50.0,
  }) async {
    if (!forceRefresh) {
      final cachedPlanets = await _dbHelper.getHabitablePlanets(
        threshold: threshold,
      );
      if (cachedPlanets.isNotEmpty) {
        return cachedPlanets;
      }
    }

    final planets = await _apiService.fetchHabitablePlanets();
    final planetsWithScores = await _calculateScoresForPlanets(planets);
    await _dbHelper.insertPlanets(planetsWithScores);

    return planetsWithScores
        .where((p) => (p.habitabilityScore ?? 0) >= threshold)
        .toList();
  }

  /// Get recent discoveries
  Future<List<Planet>> getRecentDiscoveries({
    bool forceRefresh = false,
    int years = 5,
  }) async {
    if (!forceRefresh) {
      final cachedPlanets = await _dbHelper.getRecentDiscoveries(years: years);
      if (cachedPlanets.isNotEmpty) {
        return cachedPlanets;
      }
    }

    final planets = await _apiService.fetchRecentDiscoveries(years: years);
    final planetsWithScores = await _calculateScoresForPlanets(planets);
    await _dbHelper.insertPlanets(planetsWithScores);

    return planetsWithScores;
  }

  /// Get planets in distance range
  Future<List<Planet>> getPlanetsInRange({
    required double minDistance,
    required double maxDistance,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedPlanets = await _dbHelper.getPlanetsInRange(
        minDistance: minDistance,
        maxDistance: maxDistance,
      );
      if (cachedPlanets.isNotEmpty) {
        return cachedPlanets;
      }
    }

    final planets = await _apiService.fetchPlanetsInRange(
      minDistance: minDistance,
      maxDistance: maxDistance,
    );
    final planetsWithScores = await _calculateScoresForPlanets(planets);
    await _dbHelper.insertPlanets(planetsWithScores);

    return planetsWithScores;
  }

  /// Get planets by star type
  Future<List<Planet>> getPlanetsByStarType(
    String starType, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedPlanets = await _dbHelper.getPlanetsByStarType(starType);
      if (cachedPlanets.isNotEmpty) {
        return cachedPlanets;
      }
    }

    final planets = await _apiService.fetchPlanetsByStarType(starType);
    final planetsWithScores = await _calculateScoresForPlanets(planets);
    await _dbHelper.insertPlanets(planetsWithScores);

    return planetsWithScores;
  }

  /// Search planets by name
  Future<List<Planet>> searchPlanets(String query) async {
    // Search in local database first
    final localResults = await _dbHelper.searchPlanets(query);
    if (localResults.isNotEmpty) {
      return localResults;
    }

    // If no local results, try API search
    try {
      final apiResults = await _apiService.searchPlanetsByName(query);
      final planetsWithScores = await _calculateScoresForPlanets(apiResults);

      // Save API results to database
      if (planetsWithScores.isNotEmpty) {
        await _dbHelper.insertPlanets(planetsWithScores);
      }

      return planetsWithScores;
    } catch (e) {
      print('API search failed: $e');
      return [];
    }
  }

  /// Get a single planet by name
  Future<Planet?> getPlanetByName(String name) async {
    // Check database first
    var planet = await _dbHelper.getPlanetByName(name);
    if (planet != null) {
      return planet;
    }

    // Try fetching from API
    try {
      final planets = await _apiService.searchPlanetsByName(name);
      if (planets.isNotEmpty) {
        final planetsWithScores = await _calculateScoresForPlanets(planets);
        await _dbHelper.insertPlanets(planetsWithScores);
        return planetsWithScores.first;
      }
    } catch (e) {
      print('Error fetching planet: $e');
    }

    return null;
  }

  /// Get favorite planets
  Future<List<Planet>> getFavoritePlanets() async {
    return await _dbHelper.getFavoritePlanets();
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String planetName) async {
    return await _dbHelper.toggleFavorite(planetName);
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _dbHelper.getCacheStats();
  }

  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    return await _dbHelper.getSearchHistory(limit: limit);
  }

  /// Clear old cache
  Future<void> clearOldCache({int daysOld = 7}) async {
    await _dbHelper.clearOldCache(daysOld: daysOld);
  }

  /// Refresh all data from API
  Future<void> refreshAllData() async {
    print('Refreshing all data from NASA API...');

    // Clear non-favorite planets
    await _dbHelper.clearNonFavorites();

    // Fetch fresh data
    await getPlanets(forceRefresh: true, limit: 100);
  }

  /// Export favorites
  Future<List<Map<String, dynamic>>> exportFavorites() async {
    return await _dbHelper.exportFavorites();
  }

  /// Calculate habitability scores for a list of planets
  Future<List<Planet>> _calculateScoresForPlanets(List<Planet> planets) async {
    final List<Planet> updatedPlanets = [];

    for (var planet in planets) {
      if (planet.hasSufficientData) {
        final result = _calculator.calculateHabitability(planet);
        updatedPlanets.add(
          planet.copyWith(habitabilityScore: result.overallScore),
        );
      } else {
        updatedPlanets.add(planet);
      }
    }

    return updatedPlanets;
  }

  /// Sync favorites with API (get latest data for favorite planets)
  Future<void> syncFavorites() async {
    final favorites = await getFavoritePlanets();

    for (var favorite in favorites) {
      try {
        final planets = await _apiService.searchPlanetsByName(favorite.name);
        if (planets.isNotEmpty) {
          final updated = planets.first.copyWith(isFavorite: true);
          await _dbHelper.insertPlanet(updated);
        }
      } catch (e) {
        print('Error syncing favorite ${favorite.name}: $e');
      }
    }
  }

  /// Get planets by discovery method
  Future<List<Planet>> getPlanetsByDiscoveryMethod(String method) async {
    final allPlanets = await _dbHelper.getAllPlanets();
    return allPlanets
        .where(
          (p) =>
              p.discoveryMethod?.toLowerCase().contains(method.toLowerCase()) ??
              false,
        )
        .toList();
  }

  /// Get planets by year range
  Future<List<Planet>> getPlanetsByYearRange({
    required int startYear,
    required int endYear,
  }) async {
    final allPlanets = await _dbHelper.getAllPlanets();
    return allPlanets.where((p) {
      if (p.discoveryYear == null) return false;
      return p.discoveryYear! >= startYear && p.discoveryYear! <= endYear;
    }).toList();
  }

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final cacheStats = await getCacheStats();
    final allPlanets = await _dbHelper.getAllPlanets();

    // Calculate additional statistics
    final planetsWithData = allPlanets.where((p) => p.hasSufficientData).length;
    final averageHabitability =
        allPlanets
            .where((p) => p.habitabilityScore != null)
            .map((p) => p.habitabilityScore!)
            .fold<double>(0, (sum, score) => sum + score) /
        allPlanets.where((p) => p.habitabilityScore != null).length;

    final discoveryMethods = <String, int>{};
    for (var planet in allPlanets) {
      if (planet.discoveryMethod != null) {
        discoveryMethods[planet.discoveryMethod!] =
            (discoveryMethods[planet.discoveryMethod!] ?? 0) + 1;
      }
    }

    return {
      ...cacheStats,
      'planetsWithData': planetsWithData,
      'averageHabitability': averageHabitability.isNaN
          ? 0
          : averageHabitability,
      'discoveryMethods': discoveryMethods,
      'oldestDiscovery': allPlanets
          .where((p) => p.discoveryYear != null)
          .map((p) => p.discoveryYear!)
          .fold<int?>(
            null,
            (min, year) => min == null || year < min ? year : min,
          ),
      'newestDiscovery': allPlanets
          .where((p) => p.discoveryYear != null)
          .map((p) => p.discoveryYear!)
          .fold<int?>(
            null,
            (max, year) => max == null || year > max ? year : max,
          ),
    };
  }
}
