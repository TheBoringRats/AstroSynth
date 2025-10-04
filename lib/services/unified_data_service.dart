import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/planet.dart';
import 'mock_planet_data.dart';
import 'planet_cache_service.dart';
import 'planet_cache_service_sqlite.dart';

/// Unified data service with priority cascade: CSV → Cache → API → Mock
/// Handles CORS issues, network errors, and provides seamless fallback
/// Uses SQLite for mobile/desktop, IndexedDB for web
class UnifiedDataService {
  static final UnifiedDataService _instance = UnifiedDataService._internal();
  factory UnifiedDataService() => _instance;
  UnifiedDataService._internal();

  final http.Client _client = http.Client();

  // Platform-aware cache service
  dynamic _cacheService;
  bool get _isWeb => kIsWeb;

  List<Planet>? _cachedPlanets;
  DateTime? _cacheTimestamp;
  bool _isLoadingFromAPI = false;
  bool _isCacheInitialized = false;

  /// Get the appropriate cache service for the current platform
  dynamic get cacheService {
    _cacheService ??= _isWeb
        ? PlanetCacheService.instance
        : PlanetCacheServiceSQLite();
    return _cacheService;
  }

  /// Fetch planets with OFFLINE-FIRST architecture
  /// Priority: 1) Local Cache (SQLite/IndexedDB) 2) Bundled CSV Asset 3) NASA TAP API (optional) 4) Mock Data
  /// The app works 100% offline using bundled CSV data
  /// Uses SQLite on mobile/desktop, IndexedDB on web
  Future<List<Planet>> fetchPlanets({
    int limit = 100,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Initialize IndexedDB cache if not already done
    if (!_isCacheInitialized) {
      await cacheService.initialize();
      _isCacheInitialized = true;
    }

    // 1. Check local cache first (SQLite on mobile, IndexedDB on web)
    // ALWAYS use cache if it exists (unless forceRefresh=true)
    if (!forceRefresh) {
      final cacheSize = await cacheService.getCacheSize();
      if (cacheSize > 0) {
        final cached = await cacheService.getCachedPlanets();
        if (cached.isNotEmpty) {
          final metadata = await cacheService.getMetadata();
          print(
            '[CACHE] Using ${cached.length} cached planets from storage (last updated: ${metadata?['lastUpdated']}) - OFFLINE MODE',
          );
          _cachedPlanets = cached;
          _cacheTimestamp = metadata?['lastUpdated'] as DateTime?;
          return _getPaginatedPlanets(cached, limit, offset);
        }
      } else {
        print('[INFO] Cache is empty - will load from bundled data');
      }
    } else {
      print('[REFRESH] Force refresh requested - clearing cache');
    }

    // Check in-memory cache
    if (!forceRefresh && _cachedPlanets != null && _cacheTimestamp != null) {
      print(
        '[MEMORY] Using in-memory cached planets (${_cachedPlanets!.length} planets)',
      );
      return _getPaginatedPlanets(_cachedPlanets!, limit, offset);
    }

    // Prevent multiple simultaneous loads
    if (_isLoadingFromAPI) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cachedPlanets != null) {
        return _getPaginatedPlanets(_cachedPlanets!, limit, offset);
      }
    }

    _isLoadingFromAPI = true;

    // 2. Try bundled JSON asset FIRST (Works on all platforms, reliable)
    // This ensures consistent experience across web and mobile
    try {
      print('[DATA] Loading planets from bundled JSON (OFFLINE-FIRST)...');
      final jsonPlanets = await _fetchFromLocalJSON();
      if (jsonPlanets.isNotEmpty) {
        _cachedPlanets = jsonPlanets;
        _cacheTimestamp = DateTime.now();
        _isLoadingFromAPI = false;

        // Cache in storage for persistence
        await cacheService.cachePlanets(jsonPlanets);
        print(
          '[SUCCESS] Loaded and cached ${jsonPlanets.length} planets from JSON - APP READY (OFFLINE)',
        );
        return _getPaginatedPlanets(jsonPlanets, limit, offset);
      }
    } catch (e) {
      print('[WARNING] JSON Asset failed: $e');
    }

    // 3. Try NASA TAP API (OPTIONAL - only if CSV fails)
    try {
      print('🌐 Attempting NASA TAP API as fallback...');
      final apiPlanets = await _fetchFromTAPAPI(limit, offset);
      if (apiPlanets.isNotEmpty) {
        _cachedPlanets = apiPlanets;
        _cacheTimestamp = DateTime.now();
        _isLoadingFromAPI = false;

        // Cache in IndexedDB for persistence
        await cacheService.cachePlanets(apiPlanets);
        print(
          '✅ Loaded ${apiPlanets.length} planets from NASA TAP API and cached',
        );
        return apiPlanets;
      }
    } catch (e) {
      print('⚠️ NASA TAP API failed: $e');
    }

    // 4. Fallback to mock data (last resort)
    _isLoadingFromAPI = false;
    final allMockPlanets = MockPlanetData.getMockPlanets();
    print('ℹ️ Falling back to mock data (${allMockPlanets.length} planets)');
    _cachedPlanets = allMockPlanets;
    _cacheTimestamp = DateTime.now();
    return _getPaginatedPlanets(allMockPlanets, limit, offset);
  }

  /// Fetch from NASA TAP API using proper ADQL query format
  Future<List<Planet>> _fetchFromTAPAPI(int limit, int offset) async {
    // NASA Exoplanet Archive TAP Service
    // Documentation: https://exoplanetarchive.ipac.caltech.edu/docs/TAP/usingTAP.html

    // Build ADQL query with proper column names from PS table
    // Using columns that are most likely to have data
    // IMPORTANT: We don't use LIMIT/OFFSET in ADQL because the API returns all matching rows
    // We'll filter on the client side to avoid the hasSufficientData filter reducing our batch size
    final query =
        '''
SELECT
  pl_name,
  hostname,
  sy_dist,
  pl_orbper,
  pl_rade,
  pl_bmasse,
  pl_eqt,
  pl_orbsmax,
  pl_orbeccen,
  st_spectype,
  st_teff,
  st_rad,
  st_mass,
  disc_year,
  discoverymethod,
  ra,
  dec,
  default_flag
FROM ps
WHERE default_flag = 1
ORDER BY disc_year DESC
'''
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    // TAP sync endpoint with properly formatted query
    final baseUrl = 'https://exoplanetarchive.ipac.caltech.edu/TAP/sync';

    // Build URI with query parameters
    final uri = Uri.parse(
      baseUrl,
    ).replace(queryParameters: {'query': query, 'format': 'json'});

    print('🌐 Attempting NASA TAP API...');
    print('📍 URL: $baseUrl');
    print('🔍 Query: ${query.substring(0, 100)}...');

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'AstroSynth/1.0.0 (NASA Space Apps Challenge)',
            },
          )
          .timeout(
            const Duration(
              seconds: 30,
            ), // Increased timeout for fetching all planets
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = response.body;

        // Check if response is actually JSON
        if (responseBody.trim().startsWith('[') ||
            responseBody.trim().startsWith('{')) {
          final List<dynamic> data = json.decode(responseBody);
          print(
            '[SUCCESS] Successfully parsed ${data.length} planets from TAP API',
          );

          // NASA API returns ALL planets at once, so no need to paginate
          // Just return all planets (caller can slice if needed)
          return data
              .map((json) => Planet.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
            'Response is not valid JSON: ${responseBody.substring(0, 100)}',
          );
        }
      } else {
        final errorBody = response.body.substring(0, 200);
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      print('[ERROR] TAP API Error: $e');
      rethrow;
    }
  }

  /// Fetch from bundled SQLite database (BEST PERFORMANCE)
  /// Only available on mobile/desktop platforms (not web)
  Future<List<Planet>> _fetchFromBundledSQLite(int limit, int offset) async {
    try {
      // Import here to avoid web compilation issues
      final dbPath = await getDatabasesPath();
      final targetPath = join(dbPath, 'exoplanets_bundled.db');

      // Check if database exists, if not copy from assets
      final exists = await databaseExists(targetPath);
      if (!exists) {
        print('[DB] Copying bundled database from assets...');
        final ByteData data = await rootBundle.load(
          'assets/data/exoplanets.db',
        );
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await Directory(dbPath).create(recursive: true);
        await File(targetPath).writeAsBytes(bytes, flush: true);
        print('[DB] Database copied successfully');
      }

      // Open database
      final db = await openDatabase(targetPath, readOnly: true);

      // Query planets with pagination
      final maps = await db.query(
        'planets',
        orderBy: 'disc_year DESC',
        limit: limit,
        offset: offset,
      );

      await db.close();

      // Convert to Planet objects
      final planets = <Planet>[];
      for (final map in maps) {
        try {
          // Map database columns to Planet model
          final planetJson = {
            'pl_name': map['pl_name'],
            'hostname': map['hostname'],
            'sy_dist': map['sy_dist'],
            'pl_orbper': map['pl_orbper'],
            'pl_rade': map['pl_rade'],
            'pl_bmasse': map['pl_bmasse'],
            'pl_eqt': map['pl_eqt'],
            'pl_orbsmax': map['pl_orbsmax'],
            'pl_orbeccen': map['pl_orbeccen'],
            'st_spectype': map['st_spectype'],
            'st_teff': map['st_teff'],
            'st_rad': map['st_rad'],
            'st_mass': map['st_mass'],
            'disc_year': map['disc_year'],
            'discoverymethod': map['discoverymethod'],
            'ra': map['ra'],
            'dec': map['dec'],
            'default_flag': map['default_flag'],
          };

          planets.add(Planet.fromJson(planetJson));
        } catch (e) {
          print('[WARNING] Failed to parse planet from SQLite: $e');
        }
      }

      return planets;
    } catch (e) {
      print('[ERROR] SQLite query failed: $e');
      rethrow;
    }
  }

  /// Fetch from bundled JSON asset file (6000+ planets)
  Future<List<Planet>> _fetchFromLocalJSON() async {
    print('[JSON] Loading from bundled JSON asset...');

    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/Exoplanet_FULL.json',
      );

      // Parse JSON array
      final List<dynamic> jsonData = json.decode(jsonString);

      print('[JSON] Parsing ${jsonData.length} planets from JSON...');

      // Convert to Planet objects
      final planets = <Planet>[];
      int validPlanets = 0;
      int skippedPlanets = 0;

      for (var i = 0; i < jsonData.length; i++) {
        try {
          final planetJson = jsonData[i] as Map<String, dynamic>;

          // Only require planet name
          if (planetJson.containsKey('pl_name') &&
              planetJson['pl_name'] != null &&
              planetJson['pl_name'].toString().isNotEmpty) {
            final planet = Planet.fromJson(planetJson);
            planets.add(planet);
            validPlanets++;
          } else {
            skippedPlanets++;
          }
        } catch (e) {
          skippedPlanets++;
          if (skippedPlanets < 5) {
            print('[WARNING] Failed to parse planet $i: $e');
          }
        }
      }

      print(
        '[SUCCESS] Loaded $validPlanets planets from JSON (skipped $skippedPlanets)',
      );

      return planets;
    } catch (e) {
      print('[ERROR] JSON Asset Error: $e');
      rethrow;
    }
  }

  /// Fetch from bundled CSV asset file (DEPRECATED - use JSON instead)
  /// This method is kept for reference but no longer used
  // ignore: unused_element
  Future<List<Planet>> _fetchFromLocalCSV(int limit, int offset) async {
    print('[CSV] Loading from bundled CSV asset...');

    try {
      // Load CSV from assets
      final csvString = await rootBundle.loadString(
        'assets/data/exoplanets_curated.csv',
      );

      // Split by newlines and remove empty lines
      final lines = csvString
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty || lines.length < 2) {
        throw Exception('CSV file is empty or invalid');
      }

      // Parse header - handle quoted fields properly
      final headerLine = lines[0];
      final headers = _parseCSVLine(headerLine);
      print(
        '[CSV] Headers (${headers.length} columns): ${headers.take(10).join(", ")}...',
      );

      // Parse data rows
      final planets = <Planet>[];
      int validRows = 0;
      int skippedRows = 0;

      for (var i = 1; i < lines.length && validRows < 10000; i++) {
        try {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final values = _parseCSVLine(line);
          if (values.length < 10) {
            skippedRows++;
            continue; // Skip incomplete rows
          }

          // Create JSON map from CSV row with proper type conversion
          final json = <String, dynamic>{};
          for (var j = 0; j < headers.length && j < values.length; j++) {
            final value = values[j].trim();
            // Skip empty, null, and NaN values
            if (value.isEmpty ||
                value.toLowerCase() == 'null' ||
                value.toLowerCase() == 'nan') {
              continue;
            }

            // Convert numeric strings to actual numbers
            final header = headers[j];
            if (_isNumericField(header)) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                // Convert to int if it's a year or count field
                if (header.contains('year') || header.contains('_num')) {
                  json[header] = numValue.toInt();
                } else {
                  json[header] = numValue;
                }
              }
            } else {
              // Keep as string
              json[header] = value;
            }
          }

          // Only require planet name to be present
          if (json.containsKey('pl_name') &&
              json['pl_name'].toString().isNotEmpty) {
            try {
              final planet = Planet.fromJson(json);
              planets.add(planet);
              validRows++;
            } catch (e) {
              // Skip planets that fail to parse
              skippedRows++;
              if (skippedRows < 5) {
                print('[WARNING] Failed to parse planet row $i: $e');
              }
            }
          } else {
            skippedRows++;
          }
        } catch (e) {
          // Skip malformed rows
          skippedRows++;
          continue;
        }
      }

      print(
        '[SUCCESS] Loaded ${planets.length} planets from CSV asset (skipped $skippedRows invalid rows)',
      );

      // Return all planets (no pagination at this level)
      return planets;
    } catch (e) {
      print('[ERROR] CSV Asset Error: $e');
      rethrow;
    }
  }

  /// Parse a CSV line handling quoted fields with commas
  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add the last field
    fields.add(buffer.toString());

    return fields;
  }

  /// Check if a field should be parsed as a number
  bool _isNumericField(String fieldName) {
    // All numeric fields from the NASA Exoplanet Archive
    const numericFields = [
      'sy_dist',
      'pl_orbper',
      'pl_rade',
      'pl_bmasse',
      'pl_eqt',
      'pl_orbsmax',
      'pl_orbeccen',
      'st_teff',
      'st_rad',
      'st_mass',
      'disc_year',
      'pl_radj',
      'pl_massj',
      'pl_orbincl',
      'pl_dens',
      'pl_trandep',
      'pl_trandur',
      'pl_tranmid',
      'pl_insol',
      'pl_ratror',
      'st_met',
      'st_logg',
      'st_age',
      'st_vsin',
      'st_radv',
      'sy_plx',
      'sy_pmra',
      'sy_pmdec',
      'sy_pm',
      'ra',
      'dec',
      'glon',
      'glat',
    ];

    return numericFields.contains(fieldName);
  }

  /// Get paginated subset of planets
  List<Planet> _getPaginatedPlanets(
    List<Planet> planets,
    int limit,
    int offset,
  ) {
    final start = offset.clamp(0, planets.length);
    final end = (offset + limit).clamp(0, planets.length);
    return planets.sublist(start, end);
  }

  /// Search planets by name
  Future<List<Planet>> searchPlanetsByName(String query) async {
    if (_cachedPlanets == null) {
      await fetchPlanets();
    }

    if (_cachedPlanets == null || _cachedPlanets!.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    return _cachedPlanets!.where((planet) {
      return planet.name.toLowerCase().contains(lowercaseQuery) ||
          (planet.hostStarName?.toLowerCase().contains(lowercaseQuery) ??
              false);
    }).toList();
  }

  /// Get planet by exact name
  Future<Planet?> getPlanetByName(String name) async {
    if (_cachedPlanets == null) {
      await fetchPlanets();
    }

    if (_cachedPlanets == null || _cachedPlanets!.isEmpty) {
      return null;
    }

    try {
      return _cachedPlanets!.firstWhere(
        (planet) => planet.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Filter planets by criteria
  Future<List<Planet>> filterPlanets({
    double? minHabitability,
    double? maxHabitability,
    double? minRadius,
    double? maxRadius,
    double? minMass,
    double? maxMass,
    List<String>? discoveryMethods,
    int? minDiscoveryYear,
    int? maxDiscoveryYear,
  }) async {
    if (_cachedPlanets == null) {
      await fetchPlanets();
    }

    if (_cachedPlanets == null || _cachedPlanets!.isEmpty) {
      return [];
    }

    return _cachedPlanets!.where((planet) {
      if (minRadius != null && (planet.radius ?? 0) < minRadius) return false;
      if (maxRadius != null && (planet.radius ?? 0) > maxRadius) return false;
      if (minMass != null && (planet.mass ?? 0) < minMass) return false;
      if (maxMass != null && (planet.mass ?? 0) > maxMass) return false;
      if (discoveryMethods != null &&
          !discoveryMethods.contains(planet.discoveryMethod)) {
        return false;
      }
      if (minDiscoveryYear != null &&
          (planet.discoveryYear ?? 0) < minDiscoveryYear) {
        return false;
      }
      if (maxDiscoveryYear != null &&
          (planet.discoveryYear ?? 0) > maxDiscoveryYear) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Load all planets with OFFLINE-FIRST architecture
  /// Priority: 1) Local Cache (SQLite/IndexedDB) 2) Bundled CSV 3) NASA API (optional)
  /// Uses SQLite for mobile/desktop, IndexedDB for web
  Future<List<Planet>> loadAllPlanets({
    Function(int loaded, int total)? onProgress,
    int batchSize = 100,
    bool forceRefresh = false,
  }) async {
    // Initialize IndexedDB cache if not already done
    if (!_isCacheInitialized) {
      await cacheService.initialize();
      _isCacheInitialized = true;
    }

    // 1. CHECK CACHE FIRST - always prefer cached data
    if (!forceRefresh) {
      final cacheSize = await cacheService.getCacheSize();
      if (cacheSize > 0) {
        print(
          '[CACHE] Found $cacheSize planets in cache - using cached data (OFFLINE MODE)',
        );
        final cached = await cacheService.getCachedPlanets();
        _cachedPlanets = cached;
        _cacheTimestamp = DateTime.now();

        // Report progress for cached data
        onProgress?.call(cached.length, cached.length);

        return cached;
      }
    }

    print('[DATA] Loading planets from bundled JSON (OFFLINE-FIRST)...');

    // 2. Load from bundled JSON asset (primary data source for offline)
    try {
      final jsonPlanets = await _fetchFromLocalJSON();

      if (jsonPlanets.isEmpty) {
        print('[WARNING] JSON file parsed but contains no valid planet data');
      } else {
        final totalPlanets = jsonPlanets.length;
        print('[SUCCESS] Loaded $totalPlanets planets from bundled JSON');

        // Cache planets in batches to show progress
        print('[CACHE] Caching $totalPlanets planets to storage...');

        final cachedBatches = <Planet>[];
        for (int i = 0; i < jsonPlanets.length; i += batchSize) {
          final end = (i + batchSize < jsonPlanets.length)
              ? i + batchSize
              : jsonPlanets.length;
          final batch = jsonPlanets.sublist(i, end);

          // Cache this batch
          await cacheService.cachePlanets(batch);
          cachedBatches.addAll(batch);

          // Report progress
          onProgress?.call(cachedBatches.length, totalPlanets);
          print(
            '[PROGRESS] Cached: ${cachedBatches.length}/$totalPlanets planets',
          );

          // Small delay to prevent UI freezing
          await Future.delayed(const Duration(milliseconds: 50));
        }

        _cachedPlanets = jsonPlanets;
        _cacheTimestamp = DateTime.now();
        print(
          '[SUCCESS] Successfully cached all $totalPlanets planets - APP READY (OFFLINE)',
        );

        return jsonPlanets;
      }
    } catch (e) {
      print('[ERROR] Error loading JSON: $e');
    }

    // 3. Try NASA API as last resort (will likely fail in browser due to CORS)
    try {
      print('[API] Attempting NASA API (fallback)...');
      final allPlanetsFromAPI = await _fetchFromTAPAPI(10000, 0);

      if (allPlanetsFromAPI.isNotEmpty) {
        final totalPlanets = allPlanetsFromAPI.length;
        print('[SUCCESS] Received $totalPlanets planets from NASA API');

        // Cache planets in batches
        print('[CACHE] Caching $totalPlanets planets from API...');

        final cachedBatches = <Planet>[];
        for (int i = 0; i < allPlanetsFromAPI.length; i += batchSize) {
          final end = (i + batchSize < allPlanetsFromAPI.length)
              ? i + batchSize
              : allPlanetsFromAPI.length;
          final batch = allPlanetsFromAPI.sublist(i, end);

          await cacheService.cachePlanets(batch);
          cachedBatches.addAll(batch);

          onProgress?.call(cachedBatches.length, totalPlanets);
          print(
            '[PROGRESS] Cached: ${cachedBatches.length}/$totalPlanets planets',
          );

          await Future.delayed(const Duration(milliseconds: 50));
        }

        _cachedPlanets = allPlanetsFromAPI;
        _cacheTimestamp = DateTime.now();
        print(
          '[SUCCESS] Successfully cached all $totalPlanets planets from API',
        );

        return allPlanetsFromAPI;
      }
    } catch (e) {
      print('[WARNING] NASA API failed (expected in browser): $e');
    }

    // 4. No data available
    print('[ERROR] No data available from any source');
    return [];
  }

  /// Get loading progress information
  Future<Map<String, dynamic>> getLoadingProgress() async {
    if (!_isCacheInitialized) {
      await cacheService.initialize();
      _isCacheInitialized = true;
    }

    final cacheSize = await cacheService.getCacheSize();
    final metadata = await cacheService.getMetadata();
    final isFresh = await cacheService.isCacheFresh();

    return {
      'cachedCount': cacheSize,
      'expectedTotal': 1033,
      'percentage': cacheSize > 0 ? (cacheSize / 1033 * 100).toInt() : 0,
      'isCacheFresh': isFresh,
      'lastUpdated': metadata?['lastUpdated'],
      'isComplete': cacheSize >= 1000, // Close to expected total
    };
  }

  /// Clear cache and force refresh
  Future<void> clearCache() async {
    _cachedPlanets = null;
    _cacheTimestamp = null;

    // Clear IndexedDB cache as well
    if (_isCacheInitialized) {
      await cacheService.clearCache();
    }

    print('🗑️ Cache cleared (in-memory and IndexedDB)');
  }

  /// Get cache status (both in-memory and persistent storage)
  Future<Map<String, dynamic>> getCacheStatus() async {
    if (!_isCacheInitialized) {
      await cacheService.initialize();
      _isCacheInitialized = true;
    }

    final persistentCacheSize = await cacheService.getCacheSize();
    final metadata = await cacheService.getMetadata();

    return {
      'hasCachedData': _cachedPlanets != null || persistentCacheSize > 0,
      'inMemoryCount': _cachedPlanets?.length ?? 0,
      'persistentCacheCount': persistentCacheSize,
      'cacheType': _isWeb ? 'IndexedDB' : 'SQLite',
      'cacheAge': _cacheTimestamp != null
          ? DateTime.now().difference(_cacheTimestamp!).inMinutes
          : null,
      'cacheAgeMinutes': _cacheTimestamp != null
          ? '${DateTime.now().difference(_cacheTimestamp!).inMinutes} min ago'
          : 'No cache',
      'persistentCacheLastUpdated': metadata?['lastUpdated'],
      'cachedPlanetsCount': persistentCacheSize,
    };
  }
}

/// Exception for data fetching errors
class DataFetchException implements Exception {
  final String message;
  final int? statusCode;

  DataFetchException(this.message, {this.statusCode});

  @override
  String toString() =>
      'DataFetchException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
