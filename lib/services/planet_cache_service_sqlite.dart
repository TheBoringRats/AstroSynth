import 'package:sqflite/sqflite.dart';

import '../models/planet.dart';
import 'database_helper.dart';

/// SQLite-based caching service for mobile platforms
/// Provides fast local storage for planet data
class PlanetCacheServiceSQLite {
  static final PlanetCacheServiceSQLite _instance =
      PlanetCacheServiceSQLite._internal();
  factory PlanetCacheServiceSQLite() => _instance;
  PlanetCacheServiceSQLite._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isInitialized = false;

  /// Initialize SQLite database
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('💾 Initializing SQLite database...');
    try {
      // Initialize database by accessing it
      await _dbHelper.database;
      _isInitialized = true;
      print('✅ SQLite database initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize SQLite: $e');
      rethrow;
    }
  }

  /// Cache planets in batch
  Future<void> cachePlanets(List<Planet> planets) async {
    if (!_isInitialized) await initialize();

    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      for (final planet in planets) {
        final planetData = planet.toDatabase();
        planetData['cachedAt'] = DateTime.now().millisecondsSinceEpoch;

        batch.insert(
          'planets',
          planetData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      print('💾 Cached ${planets.length} planets to SQLite');
    } catch (e) {
      print('❌ Error caching planets: $e');
      rethrow;
    }
  }

  /// Get all cached planets
  Future<List<Planet>> getCachedPlanets() async {
    if (!_isInitialized) await initialize();

    try {
      final db = await _dbHelper.database;
      final maps = await db.query('planets', orderBy: 'name ASC');

      return maps.map((map) => Planet.fromDatabase(map)).toList();
    } catch (e) {
      print('❌ Error getting cached planets: $e');
      return [];
    }
  }

  /// Get cache size (number of planets)
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();

    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM planets');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting cache size: $e');
      return 0;
    }
  }

  /// Get cache metadata
  Future<Map<String, dynamic>?> getMetadata() async {
    if (!_isInitialized) await initialize();

    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT MAX(cachedAt) as lastUpdated FROM planets',
      );

      if (result.isNotEmpty && result.first['lastUpdated'] != null) {
        final timestamp = result.first['lastUpdated'] as int;
        return {'lastUpdated': DateTime.fromMillisecondsSinceEpoch(timestamp)};
      }
      return null;
    } catch (e) {
      print('❌ Error getting metadata: $e');
      return null;
    }
  }

  /// Check if cache is fresh (less than 24 hours old)
  Future<bool> isCacheFresh() async {
    final metadata = await getMetadata();
    if (metadata == null || metadata['lastUpdated'] == null) return false;

    final lastUpdated = metadata['lastUpdated'] as DateTime;
    final age = DateTime.now().difference(lastUpdated);
    return age.inHours < 24;
  }

  /// Clear all cached planets
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();

    try {
      final db = await _dbHelper.database;
      await db.delete('planets');
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) await initialize();

    try {
      final size = await getCacheSize();
      final metadata = await getMetadata();
      final isFresh = await isCacheFresh();

      return {
        'totalPlanets': size,
        'lastUpdated': metadata?['lastUpdated'],
        'isFresh': isFresh,
        'storageType': 'SQLite',
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {
        'totalPlanets': 0,
        'lastUpdated': null,
        'isFresh': false,
        'storageType': 'SQLite',
      };
    }
  }
}
