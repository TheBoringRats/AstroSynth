import 'dart:html' as html;

import '../models/planet.dart';

/// Local storage caching service for planets using IndexedDB
/// Supports storing large datasets (1000+ planets) efficiently
class PlanetCacheService {
  static final PlanetCacheService _instance = PlanetCacheService._internal();
  factory PlanetCacheService() => _instance;
  PlanetCacheService._internal();

  static const String _dbName = 'astrosynth_db';
  static const String _storeName = 'planets';
  static const String _metaStoreName = 'metadata';
  static const int _dbVersion = 1;

  dynamic _db;
  bool _isInitialized = false;
  bool _isInitializing = false; // Prevent concurrent initialization

  /// Initialize IndexedDB
  Future<void> initialize() async {
    // Already initialized
    if (_isInitialized && _db != null) {
      return;
    }

    // Prevent concurrent initialization
    if (_isInitializing) {
      // Wait for current initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    print('🗄️ Initializing IndexedDB...');

    try {
      // Open database - returns Future<Database> directly
      _db = await html.window.indexedDB!.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: (event) {
          print('⚙️ Creating database structure');
          final db = event.target.result as dynamic;

          // Create planets store
          if (!db.objectStoreNames!.contains(_storeName)) {
            final store = db.createObjectStore(_storeName, keyPath: 'pl_name');
            store.createIndex('disc_year', 'disc_year', unique: false);
            store.createIndex(
              'discoverymethod',
              'discoverymethod',
              unique: false,
            );
            print('✅ Created planets object store');
          }

          // Create metadata store
          if (!db.objectStoreNames!.contains(_metaStoreName)) {
            db.createObjectStore(_metaStoreName, keyPath: 'key');
            print('✅ Created metadata object store');
          }
        },
      );

      _isInitialized = true;
      _isInitializing = false;
      print('✅ IndexedDB initialized successfully');
    } catch (e) {
      print('❌ IndexedDB initialization failed: $e');
      _isInitialized = false;
      _isInitializing = false;
    }
  }

  /// Cache planets in IndexedDB
  Future<void> cachePlanets(List<Planet> planets) async {
    if (!_isInitialized || _db == null) {
      await initialize();
    }

    if (_db == null) {
      print('❌ Cannot cache: IndexedDB not available');
      return;
    }

    print('💾 Caching ${planets.length} planets...');

    try {
      final transaction = _db!.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);

      // Put all planets (IndexedDB will replace by key if exists)
      for (var planet in planets) {
        final json = planet.toJson();
        await store.put(json);
      }

      await transaction.completed;

      // Get actual count from IndexedDB after storing
      final actualCount = await getCacheSize();

      // Update metadata with actual total count
      await _updateMetadata({
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalPlanets': actualCount,
      });

      print(
        '✅ Cached ${planets.length} planets successfully (Total in DB: $actualCount)',
      );
    } catch (e) {
      print('❌ Cache error: $e');
    }
  }

  /// Get all cached planets
  Future<List<Planet>> getCachedPlanets() async {
    if (!_isInitialized || _db == null) {
      await initialize();
    }

    if (_db == null) {
      print('❌ Cannot retrieve: IndexedDB not available');
      return [];
    }

    try {
      final transaction = _db!.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);

      // getAll() returns Future directly
      final data = await store.getAll(null) as List<dynamic>;

      final planets = data.map((item) {
        // Convert LinkedMap to proper Map<String, dynamic>
        final json = <String, dynamic>{};
        (item as Map).forEach((key, value) {
          json[key.toString()] = value;
        });
        return Planet.fromJson(json);
      }).toList();

      print('📦 Retrieved ${planets.length} planets from cache');
      return planets;
    } catch (e) {
      print('❌ Cache retrieval error: $e');
      return [];
    }
  }

  /// Get cache metadata
  Future<Map<String, dynamic>?> getMetadata() async {
    if (!_isInitialized || _db == null) {
      await initialize();
    }

    if (_db == null) return null;

    try {
      final transaction = _db!.transaction(_metaStoreName, 'readonly');
      final store = transaction.objectStore(_metaStoreName);

      // getObject() returns Future directly
      final data = await store.getObject('cache_meta');

      if (data != null) {
        // Convert to proper Map<String, dynamic>
        final result = <String, dynamic>{};
        (data as Map).forEach((key, value) {
          result[key.toString()] = value;
        });
        return result;
      }
    } catch (e) {
      print('❌ Metadata retrieval error: $e');
    }

    return null;
  }

  /// Update cache metadata
  Future<void> _updateMetadata(Map<String, dynamic> metadata) async {
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_metaStoreName, 'readwrite');
      final store = transaction.objectStore(_metaStoreName);

      await store.put({'key': 'cache_meta', ...metadata});

      await transaction.completed;
    } catch (e) {
      print('❌ Metadata update error: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (!_isInitialized || _db == null) {
      await initialize();
    }

    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_storeName, 'readwrite');
      final store = transaction.objectStore(_storeName);
      await store.clear();
      await transaction.completed;

      print('🗑️ Cache cleared successfully');
    } catch (e) {
      print('❌ Cache clear error: $e');
    }
  }

  /// Check if cache exists and is fresh
  /// Cache is considered fresh for 30 days (planets don't change often)
  Future<bool> isCacheFresh({
    Duration maxAge = const Duration(days: 30),
  }) async {
    final metadata = await getMetadata();

    if (metadata == null || metadata['lastUpdated'] == null) {
      return false;
    }

    try {
      final lastUpdated = DateTime.parse(metadata['lastUpdated'] as String);
      final age = DateTime.now().difference(lastUpdated);

      print('ℹ️ Cache age: ${age.inDays} days (max: ${maxAge.inDays} days)');
      return age < maxAge;
    } catch (e) {
      return false;
    }
  }

  /// Get cache size (number of planets)
  Future<int> getCacheSize() async {
    // Don't re-initialize if not ready - just return 0
    if (!_isInitialized || _db == null) {
      return 0;
    }

    try {
      final transaction = _db!.transaction(_storeName, 'readonly');
      final store = transaction.objectStore(_storeName);

      // count() returns Future<int> directly
      final count = await store.count() as int;
      return count;
    } catch (e) {
      print('❌ Cache size error: $e');
      return 0;
    }
  }
}
