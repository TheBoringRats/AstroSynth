// Stub service for mobile - using SQLite instead of IndexedDB
class PlanetCacheService {
  static PlanetCacheService? _instance;
  
  static PlanetCacheService get instance {
    _instance ??= PlanetCacheService._();
    return _instance!;
  }
  
  PlanetCacheService._();

  Future<void> init() async {
    // Initialize SQLite database on mobile
    // For now, just a stub
  }

  Future<void> cachePlanet(String planetId, Map<String, dynamic> data) async {
    // Cache to SQLite
  }

  Future<Map<String, dynamic>?> getCachedPlanet(String planetId) async {
    // Retrieve from SQLite
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllCachedPlanets() async {
    // Get all from SQLite
    return [];
  }
}
