import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/planet.dart';

/// Service for fetching exoplanet data from NASA Exoplanet Archive
class NASAApiService {
  static final NASAApiService _instance = NASAApiService._internal();
  factory NASAApiService() => _instance;
  NASAApiService._internal();

  final http.Client _client = http.Client();

  /// Build TAP query for NASA Exoplanet Archive
  String _buildQuery({
    int limit = 20,
    int offset = 0,
    String? orderBy,
    List<String>? filters,
  }) {
    final columns = AppConstants.defaultQueryColumns.join(',');

    StringBuffer query = StringBuffer();
    query.write('SELECT $columns FROM ps ');

    // Add filters
    if (filters != null && filters.isNotEmpty) {
      query.write('WHERE ${filters.join(' AND ')} ');
    }

    // Add ordering
    if (orderBy != null) {
      query.write('ORDER BY $orderBy ');
    }

    // Add limit and offset for pagination
    query.write('LIMIT $limit OFFSET $offset');

    return query.toString();
  }

  /// Fetch planets from NASA API
  Future<List<Planet>> fetchPlanets({
    int limit = 20,
    int offset = 0,
    String? orderBy,
    List<String>? filters,
  }) async {
    try {
      final query = _buildQuery(
        limit: limit,
        offset: offset,
        orderBy: orderBy,
        filters: filters,
      );

      // Use CORS proxy for web or direct API for other platforms
      final baseUrl = AppConstants.nasaApiBaseUrl;
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {'query': query, 'format': AppConstants.nasaApiFormat},
      );

      print('Fetching planets from NASA API:');
      print(uri.toString());

      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: AppConstants.nasaApiTimeout));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('✅ Successfully fetched ${data.length} planets from NASA');

        return data.map((json) {
          try {
            return Planet.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing planet: $e');
            rethrow;
          }
        }).toList();
      } else {
        throw NASAApiException(
          'Failed to fetch planets: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NASAApiException('Network error: ${e.message}');
    } catch (e) {
      throw NASAApiException('Error fetching planets: $e');
    }
  }

  /// Search planets by name
  Future<List<Planet>> searchPlanetsByName(String name) async {
    if (name.isEmpty) {
      return fetchPlanets();
    }

    final filters = ["pl_name LIKE '%$name%'"];

    return fetchPlanets(filters: filters, limit: 50);
  }

  /// Fetch planets by discovery method
  Future<List<Planet>> fetchPlanetsByDiscoveryMethod(String method) async {
    final filters = ["discoverymethod='$method'"];

    return fetchPlanets(filters: filters, limit: 50);
  }

  /// Fetch potentially habitable planets
  Future<List<Planet>> fetchHabitablePlanets() async {
    final filters = [
      'pl_rade IS NOT NULL',
      'pl_eqt IS NOT NULL',
      'pl_rade BETWEEN ${AppConstants.minHabitableRadius} AND ${AppConstants.maxHabitableRadius}',
      'pl_eqt BETWEEN ${AppConstants.minHabitableTemp} AND ${AppConstants.maxHabitableTemp}',
    ];

    return fetchPlanets(filters: filters, orderBy: 'pl_eqt ASC', limit: 100);
  }

  /// Fetch planets discovered in a specific year
  Future<List<Planet>> fetchPlanetsByYear(int year) async {
    final filters = ['disc_year=$year'];

    return fetchPlanets(filters: filters, orderBy: 'pl_name ASC', limit: 100);
  }

  /// Fetch planets within a distance range (in parsecs)
  Future<List<Planet>> fetchPlanetsInRange({
    required double minDistance,
    required double maxDistance,
  }) async {
    final filters = [
      'sy_dist IS NOT NULL',
      'sy_dist BETWEEN $minDistance AND $maxDistance',
    ];

    return fetchPlanets(filters: filters, orderBy: 'sy_dist ASC', limit: 50);
  }

  /// Fetch planets around a specific star type
  Future<List<Planet>> fetchPlanetsByStarType(String starType) async {
    final filters = ["st_spectype LIKE '$starType%'"];

    return fetchPlanets(filters: filters, limit: 50);
  }

  /// Fetch a single planet by exact name
  Future<Planet?> fetchPlanetByName(String name) async {
    try {
      final filters = ["pl_name='$name'"];
      final results = await fetchPlanets(filters: filters, limit: 1);

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('Error fetching planet by name: $e');
      return null;
    }
  }

  /// Fetch recent discoveries (last N years)
  Future<List<Planet>> fetchRecentDiscoveries({int years = 5}) async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - years;

    final filters = ['disc_year IS NOT NULL', 'disc_year>=$startYear'];

    return fetchPlanets(
      filters: filters,
      orderBy: 'disc_year DESC, pl_name ASC',
      limit: 100,
    );
  }

  /// Get statistics about the exoplanet dataset
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Verify API is accessible
      await fetchPlanets(limit: 1);

      return {
        'totalPlanets': AppConstants.maxPlanetsToLoad,
        'lastUpdated': DateTime.now().toIso8601String(),
        'apiEndpoint': AppConstants.nasaApiBaseUrl,
      };
    } catch (e) {
      return {'error': 'Failed to fetch statistics: $e'};
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Custom exception for NASA API errors
class NASAApiException implements Exception {
  final String message;
  final int? statusCode;

  NASAApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'NASAApiException ($statusCode): $message';
    }
    return 'NASAApiException: $message';
  }
}
