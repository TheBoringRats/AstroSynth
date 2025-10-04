import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/planet.dart';

/// SQLite database helper for local data persistence
/// Handles caching of planets and favorites management
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance, create if doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('astrosynth.db');
    return _database!;
  }

  /// Initialize database with tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Planets table for caching
    await db.execute('''
      CREATE TABLE planets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        hostStarName TEXT,
        distanceFromEarth REAL,
        orbitalPeriod REAL,
        radius REAL,
        mass REAL,
        equilibriumTemperature REAL,
        semiMajorAxis REAL,
        eccentricity REAL,
        starType TEXT,
        starTemperature REAL,
        starRadius REAL,
        starMass REAL,
        discoveryYear INTEGER,
        discoveryMethod TEXT,
        habitabilityScore REAL,
        biomeType TEXT,
        isFavorite INTEGER DEFAULT 0,
        cachedAt INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_planets_name ON planets(name)');
    await db.execute(
      'CREATE INDEX idx_planets_favorite ON planets(isFavorite)',
    );
    await db.execute(
      'CREATE INDEX idx_planets_habitability ON planets(habitabilityScore)',
    );
    await db.execute('CREATE INDEX idx_planets_cached ON planets(cachedAt)');

    // Favorites metadata table
    await db.execute('''
      CREATE TABLE favorites_meta(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        planetName TEXT NOT NULL,
        addedAt INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // User search history
    await db.execute('''
      CREATE TABLE search_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searchedAt INTEGER NOT NULL,
        resultCount INTEGER
      )
    ''');
  }

  /// Insert or update a planet
  Future<int> insertPlanet(Planet planet) async {
    final db = await database;
    final planetData = planet.toDatabase();
    planetData['cachedAt'] = DateTime.now().millisecondsSinceEpoch;

    return await db.insert(
      'planets',
      planetData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple planets (bulk operation)
  Future<void> insertPlanets(List<Planet> planets) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var planet in planets) {
      final planetData = planet.toDatabase();
      planetData['cachedAt'] = now;
      batch.insert(
        'planets',
        planetData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get all cached planets
  Future<List<Planet>> getAllPlanets() async {
    final db = await database;
    final result = await db.query('planets', orderBy: 'name ASC');
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Get planet by name
  Future<Planet?> getPlanetByName(String name) async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Planet.fromDatabase(result.first);
    }
    return null;
  }

  /// Search planets by name or host star
  Future<List<Planet>> searchPlanets(String query) async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'name LIKE ? OR hostStarName LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    // Save search history
    await _saveSearchHistory(query, result.length);

    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Get favorite planets
  Future<List<Planet>> getFavoritePlanets() async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String planetName) async {
    final db = await database;

    // Get current favorite status
    final result = await db.query(
      'planets',
      columns: ['isFavorite'],
      where: 'name = ?',
      whereArgs: [planetName],
      limit: 1,
    );

    if (result.isEmpty) return false;

    final currentStatus = result.first['isFavorite'] as int;
    final newStatus = currentStatus == 1 ? 0 : 1;

    // Update favorite status
    await db.update(
      'planets',
      {'isFavorite': newStatus},
      where: 'name = ?',
      whereArgs: [planetName],
    );

    // Update favorites metadata
    if (newStatus == 1) {
      await db.insert('favorites_meta', {
        'planetName': planetName,
        'addedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.delete(
        'favorites_meta',
        where: 'planetName = ?',
        whereArgs: [planetName],
      );
    }

    return newStatus == 1;
  }

  /// Get planets with habitability score above threshold
  Future<List<Planet>> getHabitablePlanets({double threshold = 50.0}) async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'habitabilityScore >= ?',
      whereArgs: [threshold],
      orderBy: 'habitabilityScore DESC',
    );
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Get recent discoveries (last N years)
  Future<List<Planet>> getRecentDiscoveries({int years = 5}) async {
    final db = await database;
    final cutoffYear = DateTime.now().year - years;
    final result = await db.query(
      'planets',
      where: 'discoveryYear >= ?',
      whereArgs: [cutoffYear],
      orderBy: 'discoveryYear DESC',
    );
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Get planets within distance range
  Future<List<Planet>> getPlanetsInRange({
    required double minDistance,
    required double maxDistance,
  }) async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'distanceFromEarth >= ? AND distanceFromEarth <= ?',
      whereArgs: [minDistance, maxDistance],
      orderBy: 'distanceFromEarth ASC',
    );
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Get planets by star type
  Future<List<Planet>> getPlanetsByStarType(String starType) async {
    final db = await database;
    final result = await db.query(
      'planets',
      where: 'starType LIKE ?',
      whereArgs: ['$starType%'],
      orderBy: 'name ASC',
    );
    return result.map((json) => Planet.fromDatabase(json)).toList();
  }

  /// Check if cache is stale (older than 24 hours)
  Future<bool> isCacheStale() async {
    final db = await database;
    final result = await db.query(
      'planets',
      columns: ['MAX(cachedAt) as maxCached'],
    );

    if (result.isEmpty || result.first['maxCached'] == null) {
      return true;
    }

    final maxCached = result.first['maxCached'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceCache = (now - maxCached) / (1000 * 60 * 60);

    return hoursSinceCache > 24;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await database;

    final totalCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM planets'),
        ) ??
        0;

    final favoritesCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM planets WHERE isFavorite = 1',
          ),
        ) ??
        0;

    final habitableCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM planets WHERE habitabilityScore >= 50',
          ),
        ) ??
        0;

    final result = await db.query(
      'planets',
      columns: ['MAX(cachedAt) as maxCached', 'MIN(cachedAt) as minCached'],
    );

    int? lastCached;
    if (result.isNotEmpty && result.first['maxCached'] != null) {
      lastCached = result.first['maxCached'] as int;
    }

    return {
      'totalPlanets': totalCount,
      'favoritePlanets': favoritesCount,
      'habitablePlanets': habitableCount,
      'lastCachedAt': lastCached != null
          ? DateTime.fromMillisecondsSinceEpoch(lastCached)
          : null,
    };
  }

  /// Get search history
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'search_history',
      columns: ['query'],
      orderBy: 'searchedAt DESC',
      limit: limit,
      distinct: true,
    );
    return result.map((row) => row['query'] as String).toList();
  }

  /// Save search query to history
  Future<void> _saveSearchHistory(String query, int resultCount) async {
    final db = await database;
    await db.insert('search_history', {
      'query': query,
      'searchedAt': DateTime.now().millisecondsSinceEpoch,
      'resultCount': resultCount,
    });

    // Keep only last 100 searches
    await db.delete(
      'search_history',
      where:
          'id NOT IN (SELECT id FROM search_history ORDER BY searchedAt DESC LIMIT 100)',
    );
  }

  /// Clear old cache data
  Future<void> clearOldCache({int daysOld = 7}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;

    await db.delete(
      'planets',
      where: 'cachedAt < ? AND isFavorite = 0',
      whereArgs: [cutoffTime],
    );
  }

  /// Delete planet by name
  Future<int> deletePlanet(String name) async {
    final db = await database;
    return await db.delete('planets', where: 'name = ?', whereArgs: [name]);
  }

  /// Clear all planets (keep favorites)
  Future<void> clearNonFavorites() async {
    final db = await database;
    await db.delete('planets', where: 'isFavorite = 0');
  }

  /// Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('planets');
    await db.delete('favorites_meta');
    await db.delete('search_history');
  }

  /// Get planets with pagination and filtering
  Future<List<Planet>> getPlanetsWithFilters({
    int limit = 100,
    int offset = 0,
    String? searchQuery,
    int? minDiscoveryYear,
    int? maxDiscoveryYear,
    String? discoveryMethod,
    double? minRadius,
    double? maxRadius,
    String? orderBy = 'discoveryYear DESC',
  }) async {
    final db = await database;

    // Build WHERE clause
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR hostStarName LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    if (minDiscoveryYear != null) {
      whereClauses.add('discoveryYear >= ?');
      whereArgs.add(minDiscoveryYear);
    }

    if (maxDiscoveryYear != null) {
      whereClauses.add('discoveryYear <= ?');
      whereArgs.add(maxDiscoveryYear);
    }

    if (discoveryMethod != null && discoveryMethod.isNotEmpty) {
      whereClauses.add('discoveryMethod = ?');
      whereArgs.add(discoveryMethod);
    }

    if (minRadius != null) {
      whereClauses.add('radius >= ?');
      whereArgs.add(minRadius);
    }

    if (maxRadius != null) {
      whereClauses.add('radius <= ?');
      whereArgs.add(maxRadius);
    }

    final whereClause = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final maps = await db.query(
      'planets',
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => Planet.fromDatabase(map)).toList();
  }

  /// Get total count of planets (for pagination)
  Future<int> getPlanetCount({String? searchQuery}) async {
    final db = await database;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM planets WHERE name LIKE ? OR hostStarName LIKE ?',
        ['%$searchQuery%', '%$searchQuery%'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM planets');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get unique discovery methods
  Future<List<String>> getDiscoveryMethods() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT discoveryMethod FROM planets WHERE discoveryMethod IS NOT NULL ORDER BY discoveryMethod',
    );
    return result.map((row) => row['discoveryMethod'] as String).toList();
  }

  /// Bulk insert planets (for initial data load from bundled DB)
  Future<int> bulkInsertPlanets(List<Planet> planets) async {
    final db = await database;
    int inserted = 0;

    final batch = db.batch();
    for (final planet in planets) {
      final planetData = planet.toDatabase();
      planetData['cachedAt'] = DateTime.now().millisecondsSinceEpoch;

      batch.insert(
        'planets',
        planetData,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final results = await batch.commit(noResult: false);
    inserted = results.where((r) => r != 0).length;

    return inserted;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Export favorites as JSON
  Future<List<Map<String, dynamic>>> exportFavorites() async {
    final favorites = await getFavoritePlanets();
    return favorites.map((planet) => planet.toJson()).toList();
  }

  /// Get database file size
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'astrosynth.db');
    try {
      final file = await databaseFactory.databaseExists(path);
      if (file) {
        // Get file size would require dart:io which isn't available on web
        return 0;
      }
    } catch (e) {
      print('Error getting database size: $e');
    }
    return 0;
  }
}
