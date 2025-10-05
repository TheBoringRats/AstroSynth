import '../models/planet.dart';
import '../services/habitability_calculator.dart';
import '../services/mock_planet_data.dart';
import '../services/unified_data_service.dart';

/// Simplified repository for web compatibility
/// Uses UnifiedDataService with TAP API → CSV → Mock fallback
class PlanetRepository {
  final UnifiedDataService _dataService = UnifiedDataService();
  final HabitabilityCalculator _calculator = HabitabilityCalculator();

  // In-memory cache (used on all platforms for now)
  List<Planet> _cachedPlanets = [];
  List<Planet> _favoritePlanets = [];
  DateTime? _lastCacheTime;
  bool _usingMockData = false;

  /// Get planets with in-memory caching
  Future<List<Planet>> getPlanets({
    bool forceRefresh = false,
    int limit = 10000, // Load all planets (6022 from JSON)
  }) async {
    if (!forceRefresh && _cachedPlanets.isNotEmpty) {
      final cacheAge = _lastCacheTime != null
          ? DateTime.now().difference(_lastCacheTime!).inHours
          : 25;
      if (cacheAge < 24) {
        print(
          'Returning ${_cachedPlanets.length} planets from cache${_usingMockData ? " (mock data)" : ""}',
        );
        return _cachedPlanets;
      }
    }

    print('🔄 Fetching planets with unified data service...');

    try {
      // UnifiedDataService handles all fallback logic internally
      final planets = await _dataService.fetchPlanets(
        limit: limit,
        forceRefresh: forceRefresh,
      );
      final planetsWithScores = await _calculateScoresForPlanets(planets);

      _cachedPlanets = planetsWithScores;
      _lastCacheTime = DateTime.now();

      // Check cache status to determine data source
      final cacheStatus = await _dataService.getCacheStatus();
      final dataSource = cacheStatus['cachedPlanetsCount'] > 0
          ? 'real NASA data'
          : 'mock data';
      _usingMockData = dataSource == 'mock data';

      print('✅ Loaded ${planetsWithScores.length} planets from $dataSource');
      return planetsWithScores;
    } catch (e) {
      print('❌ Error fetching planets: $e');
      print('📦 Using emergency mock data fallback...');

      // Emergency fallback (should rarely happen)
      final mockPlanets = MockPlanetData.getMockPlanets();
      final allMockPlanets = mockPlanets.take(limit).toList();

      final planetsWithScores = await _calculateScoresForPlanets(
        allMockPlanets,
      );

      _cachedPlanets = planetsWithScores;
      _lastCacheTime = DateTime.now();
      _usingMockData = true;
      print('Loaded ${planetsWithScores.length} mock planets successfully');
      return planetsWithScores;
    }
  }

  /// Check if currently using mock data
  bool get isUsingMockData => _usingMockData;

  /// Get habitable planets
  Future<List<Planet>> getHabitablePlanets({double threshold = 50.0}) async {
    final allPlanets = await getPlanets();
    return allPlanets
        .where((p) => (p.habitabilityScore ?? 0) >= threshold)
        .toList()
      ..sort(
        (a, b) =>
            (b.habitabilityScore ?? 0).compareTo(a.habitabilityScore ?? 0),
      );
  }

  /// Get recent discoveries
  Future<List<Planet>> getRecentDiscoveries({int years = 5}) async {
    final allPlanets = await getPlanets();
    final cutoffYear = DateTime.now().year - years;
    return allPlanets
        .where((p) => (p.discoveryYear ?? 0) >= cutoffYear)
        .toList()
      ..sort((a, b) => (b.discoveryYear ?? 0).compareTo(a.discoveryYear ?? 0));
  }

  /// Get planets within distance range
  Future<List<Planet>> getPlanetsInRange({
    required double minDistance,
    required double maxDistance,
  }) async {
    final allPlanets = await getPlanets();
    return allPlanets.where((p) {
      final dist = p.distanceFromEarth;
      return dist != null && dist >= minDistance && dist <= maxDistance;
    }).toList()..sort(
      (a, b) => (a.distanceFromEarth ?? 0).compareTo(b.distanceFromEarth ?? 0),
    );
  }

  /// Get planets by star type
  Future<List<Planet>> getPlanetsByStarType(String starType) async {
    final allPlanets = await getPlanets();
    return allPlanets
        .where((p) => p.stellarSpectralType?.startsWith(starType) ?? false)
        .toList();
  }

  /// Search planets by name
  Future<List<Planet>> searchPlanets(String query) async {
    final allPlanets = await getPlanets();
    return allPlanets.where((planet) {
      return planet.name.toLowerCase().contains(query.toLowerCase()) ||
          (planet.hostStarName?.toLowerCase().contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  /// Get a single planet by name
  Future<Planet?> getPlanetByName(String name) async {
    final allPlanets = await getPlanets();
    try {
      return allPlanets.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get favorite planets
  Future<List<Planet>> getFavoritePlanets() async {
    // Update favorites from cached planets
    _favoritePlanets = _cachedPlanets.where((p) => p.isFavorite).toList();
    return _favoritePlanets;
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String planetName) async {
    // Find planet in cache
    final index = _cachedPlanets.indexWhere((p) => p.name == planetName);
    if (index != -1) {
      final planet = _cachedPlanets[index];
      final newStatus = !planet.isFavorite;
      _cachedPlanets[index] = planet.copyWith(isFavorite: newStatus);

      // Update favorites list
      if (newStatus) {
        _favoritePlanets.add(_cachedPlanets[index]);
      } else {
        _favoritePlanets.removeWhere((p) => p.name == planetName);
      }

      return newStatus;
    }
    return false;
  }

  /// Load all planets with progress tracking
  /// Will check cache first, only fetches from API if cache is empty
  Future<List<Planet>> loadAllPlanets({
    Function(int loaded, int total)? onProgress,
  }) async {
    try {
      // This will check cache first, then API if needed
      final planets = await _dataService.loadAllPlanets(onProgress: onProgress);

      final planetsWithScores = await _calculateScoresForPlanets(planets);

      _cachedPlanets = planetsWithScores;
      _lastCacheTime = DateTime.now();
      _usingMockData = false;

      print('✅ Loaded and cached ${planetsWithScores.length} planets');
      return planetsWithScores;
    } catch (e) {
      print('❌ Error loading all planets: $e');
      rethrow;
    }
  }

  /// Get loading progress information
  Future<Map<String, dynamic>> getLoadingProgress() async {
    return await _dataService.getLoadingProgress();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final cacheStatus = await _dataService.getCacheStatus();
    final totalCount = _cachedPlanets.length;
    final favoritesCount = _cachedPlanets.where((p) => p.isFavorite).length;
    final habitableCount = _cachedPlanets
        .where((p) => (p.habitabilityScore ?? 0) >= 50)
        .length;

    return {
      'totalPlanets': totalCount,
      'favoritePlanets': favoritesCount,
      'habitableCount': habitableCount,
      'indexedDBCount': cacheStatus['indexedDBCount'],
      'inMemoryCount': cacheStatus['inMemoryCount'],
      'indexedDBLastUpdated': cacheStatus['indexedDBLastUpdated'],
      'habitablePlanets': habitableCount,
      'lastCachedAt': _lastCacheTime,
    };
  }

  /// Refresh all data from API
  Future<void> refreshAllData() async {
    print('Refreshing all data from NASA API...');
    _cachedPlanets.clear();
    _lastCacheTime = null;
    await getPlanets(forceRefresh: true, limit: 10000); // Load all planets
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

  /// Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final cacheStats = await getCacheStats();
    final allPlanets = _cachedPlanets;

    final planetsWithData = allPlanets.where((p) => p.hasSufficientData).length;
    final habitableScores = allPlanets
        .where((p) => p.habitabilityScore != null)
        .map((p) => p.habitabilityScore!)
        .toList();

    final averageHabitability = habitableScores.isNotEmpty
        ? habitableScores.reduce((a, b) => a + b) / habitableScores.length
        : 0.0;

    final discoveryMethods = <String, int>{};
    for (var planet in allPlanets) {
      if (planet.discoveryMethod != null) {
        discoveryMethods[planet.discoveryMethod!] =
            (discoveryMethods[planet.discoveryMethod!] ?? 0) + 1;
      }
    }

    final discoveryYears = allPlanets
        .where((p) => p.discoveryYear != null && p.discoveryYear! > 0)
        .map((p) => p.discoveryYear!)
        .toList();

    return {
      ...cacheStats,
      'planetsWithData': planetsWithData,
      'averageHabitability': averageHabitability,
      'discoveryMethods': discoveryMethods,
      'oldestDiscovery': discoveryYears.isNotEmpty
          ? discoveryYears.reduce((a, b) => a < b ? a : b)
          : null,
      'newestDiscovery': discoveryYears.isNotEmpty
          ? discoveryYears.reduce((a, b) => a > b ? a : b)
          : null,
    };
  }
}
