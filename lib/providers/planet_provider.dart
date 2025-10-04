import 'package:flutter/foundation.dart';

import '../models/habitability_result.dart';
import '../models/planet.dart';
import '../services/habitability_calculator.dart';
import '../services/planet_repository_simple.dart';

/// Manages the state of planets in the app
///
/// Handles fetching, caching, favorites, and provides reactive updates
/// to all widgets listening to planet data changes.
class PlanetProvider with ChangeNotifier {
  final PlanetRepository _repository = PlanetRepository();
  final HabitabilityCalculator _calculator = HabitabilityCalculator();

  // State variables
  List<Planet> _allPlanets = [];
  List<Planet> _filteredPlanets = [];
  Set<String> _favoritePlanetIds = {};
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  // Cache statistics
  Map<String, dynamic> _cacheStats = {};

  // Getters
  List<Planet> get allPlanets => _allPlanets;
  List<Planet> get filteredPlanets => _filteredPlanets;
  Set<String> get favoritePlanetIds => _favoritePlanetIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;
  bool get hasError => _error != null;
  bool get isEmpty => _allPlanets.isEmpty && !_isLoading;
  int get totalCount => _allPlanets.length;
  int get favoriteCount => _favoritePlanetIds.length;
  Map<String, dynamic> get cacheStats => _cacheStats;
  bool get isUsingMockData => _repository.isUsingMockData;

  /// Check if a planet is favorited
  bool isFavorite(String planetName) {
    return _favoritePlanetIds.contains(planetName);
  }

  /// Get a planet by name
  Planet? getPlanetByName(String name) {
    try {
      return _allPlanets.firstWhere((planet) => planet.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all favorite planets
  List<Planet> get favoritePlanets {
    return _allPlanets
        .where((planet) => _favoritePlanetIds.contains(planet.name))
        .toList();
  }

  /// Fetch all planets from the repository
  Future<void> fetchPlanets({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.getPlanets(forceRefresh: forceRefresh);

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      // Load favorites
      await _loadFavorites();

      // Update cache stats
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch planets: $e');
      _setLoading(false);
    }
  }

  /// Fetch habitable planets only
  Future<void> fetchHabitablePlanets({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.getHabitablePlanets();

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch habitable planets: $e');
      _setLoading(false);
    }
  }

  /// Fetch recently discovered planets
  Future<void> fetchRecentDiscoveries({bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.getRecentDiscoveries();

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch recent discoveries: $e');
      _setLoading(false);
    }
  }

  /// Fetch planets within a distance range
  Future<void> fetchPlanetsInRange({
    required double minDistance,
    required double maxDistance,
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.getPlanetsInRange(
        minDistance: minDistance,
        maxDistance: maxDistance,
      );

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch planets in range: $e');
      _setLoading(false);
    }
  }

  /// Fetch planets by star type
  Future<void> fetchPlanetsByStarType({
    required String starType,
    bool forceRefresh = false,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.getPlanetsByStarType(starType);

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch planets by star type: $e');
      _setLoading(false);
    }
  }

  /// Search planets by name
  Future<void> searchPlanets(String query, {bool forceRefresh = false}) async {
    try {
      _setLoading(true);
      _clearError();

      if (query.isEmpty) {
        await fetchPlanets(forceRefresh: forceRefresh);
        return;
      }

      final planets = await _repository.searchPlanets(query);

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to search planets: $e');
      _setLoading(false);
    }
  }

  /// Toggle favorite status of a planet
  Future<bool> toggleFavorite(String planetName) async {
    try {
      final isFavorite = await _repository.toggleFavorite(planetName);

      if (isFavorite) {
        _favoritePlanetIds.add(planetName);
      } else {
        _favoritePlanetIds.remove(planetName);
      }

      notifyListeners();
      return isFavorite;
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      return false;
    }
  }

  /// Load favorites from repository
  Future<void> _loadFavorites() async {
    try {
      final favorites = await _repository.getFavoritePlanets();
      _favoritePlanetIds = favorites.map((p) => p.name).toSet();
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  /// Calculate habitability for a planet
  Future<HabitabilityResult?> calculateHabitability(Planet planet) async {
    try {
      return await _calculator.calculateHabitability(planet);
    } catch (e) {
      debugPrint('Failed to calculate habitability: $e');
      return null;
    }
  }

  /// Apply local filter to planets (client-side filtering)
  void applyLocalFilter({
    bool? showFavoritesOnly,
    bool? showHabitableOnly,
    double? minHabitability,
    String? biomeType,
  }) {
    _filteredPlanets = _allPlanets.where((planet) {
      // Filter favorites
      if (showFavoritesOnly == true &&
          !_favoritePlanetIds.contains(planet.name)) {
        return false;
      }

      // Filter habitable
      if (showHabitableOnly == true) {
        final habitability = planet.habitabilityScore ?? 0.0;
        if (habitability < 50.0) return false;
      }

      // Filter by minimum habitability
      if (minHabitability != null) {
        final habitability = planet.habitabilityScore ?? 0.0;
        if (habitability < minHabitability) return false;
      }

      // Filter by biome type
      if (biomeType != null && biomeType.isNotEmpty) {
        if (planet.biomeType != biomeType) return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// Sort planets by criteria
  void sortPlanets(String sortBy, {bool ascending = true}) {
    _filteredPlanets.sort((a, b) {
      int comparison = 0;

      switch (sortBy.toLowerCase()) {
        case 'name':
          comparison = a.displayName.compareTo(b.displayName);
          break;
        case 'year':
          comparison = (a.discoveryYear ?? 0).compareTo(b.discoveryYear ?? 0);
          break;
        case 'distance':
          comparison = (a.distanceFromEarth ?? double.infinity).compareTo(
            b.distanceFromEarth ?? double.infinity,
          );
          break;
        case 'habitability':
          comparison = (b.habitabilityScore ?? 0.0).compareTo(
            a.habitabilityScore ?? 0.0,
          );
          break;
        case 'mass':
          comparison = (a.mass ?? 0.0).compareTo(b.mass ?? 0.0);
          break;
        case 'radius':
          comparison = (a.radius ?? 0.0).compareTo(b.radius ?? 0.0);
          break;
        default:
          comparison = 0;
      }

      return ascending ? comparison : -comparison;
    });

    notifyListeners();
  }

  /// Load all planets with progress tracking
  Future<void> loadAllPlanetsWithProgress({
    Function(int loaded, int total)? onProgress,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final planets = await _repository.loadAllPlanets(onProgress: onProgress);

      _allPlanets = planets;
      _filteredPlanets = planets;
      _lastFetchTime = DateTime.now();

      await _loadFavorites();
      _cacheStats = await _repository.getCacheStats();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load all planets: $e');
      _setLoading(false);
    }
  }

  /// Get loading progress from repository
  Future<Map<String, dynamic>> getLoadingProgress() async {
    return await _repository.getLoadingProgress();
  }

  /// Refresh planets (force refresh from API)
  Future<void> refresh() async {
    await fetchPlanets(forceRefresh: true);
  }

  /// Clear all data
  void clear() {
    _allPlanets = [];
    _filteredPlanets = [];
    _favoritePlanetIds.clear();
    _error = null;
    _lastFetchTime = null;
    _cacheStats = {};
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
