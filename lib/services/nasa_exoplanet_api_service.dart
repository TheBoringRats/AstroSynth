import 'dart:convert';

import 'package:http/http.dart' as http;

/// NASA Exoplanet API Service
///
/// Fetches official NASA exoplanet data including:
/// - High-resolution images
/// - Discovery information
/// - Physical properties
/// - 3D visualization links
class NASAExoplanetAPIService {
  static const String _baseUrl =
      'https://science.nasa.gov/wp-json/wp/v2/exoplanet';

  /// Fetch exoplanet data by exo_id
  /// Example: exoId = "KMT-2021-BLG-0736L_b"
  Future<NASAExoplanetData?> getExoplanetByExoId(String exoId) async {
    try {
      final url = Uri.parse('$_baseUrl?exo_id=$exoId');
      print('[NASA-API] Fetching data for: $exoId');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          final planetData = NASAExoplanetData.fromJson(data[0]);
          print('[NASA-API] ✅ Fetched data for: ${planetData.displayName}');
          return planetData;
        } else {
          print('[NASA-API] ⚠️ No data found for: $exoId');
          return null;
        }
      } else {
        print('[NASA-API] ❌ Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[NASA-API] ❌ Exception: $e');
      return null;
    }
  }

  /// Fetch exoplanet data by planet name
  /// Example: name = "Kepler-442b"
  Future<NASAExoplanetData?> getExoplanetByName(String name) async {
    try {
      // Convert name to exo_id format (replace space with underscore, add _b if needed)
      String exoId = name.replaceAll(' ', '_');
      if (!exoId.contains('_') && !exoId.endsWith('b')) {
        exoId = '${exoId}_b';
      }

      return await getExoplanetByExoId(exoId);
    } catch (e) {
      print('[NASA-API] ❌ Exception: $e');
      return null;
    }
  }

  /// Search for exoplanets (returns multiple results)
  Future<List<NASAExoplanetData>> searchExoplanets({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl?page=$page&per_page=$perPage');
      print('[NASA-API] Searching exoplanets (page $page)...');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final planets = data
            .map((json) => NASAExoplanetData.fromJson(json))
            .toList();

        print('[NASA-API] ✅ Found ${planets.length} exoplanets');
        return planets;
      } else {
        print('[NASA-API] ❌ Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('[NASA-API] ❌ Exception: $e');
      return [];
    }
  }
}

/// NASA Exoplanet Data Model
class NASAExoplanetData {
  final int id;
  final String slug;
  final String displayName;
  final String? subtitle;
  final String description;
  final String? shortDescription;

  // Planet Properties
  final String planetType;
  final String? planetMass;
  final String? planetRadius;
  final String? planetOrbitPeriod;
  final double? orbitalDistance; // AU
  final String? eccentricity;

  // Discovery Info
  final String discoveryMethod;
  final String facility;
  final int? discoveryYear;
  final String? publicationDate;

  // Star Properties
  final int? starId;
  final double? starDistance; // light years
  final String? starMagnitude;

  // Images
  final int? featuredMediaId;
  final String? featuredImageUrl;

  // Links
  final String link;
  final String? eyesOnExoplanetsUrl;

  // Classification
  final String? planetSizeClass;
  final bool? isKepler;
  final bool? multiPlanetSystem;

  NASAExoplanetData({
    required this.id,
    required this.slug,
    required this.displayName,
    this.subtitle,
    required this.description,
    this.shortDescription,
    required this.planetType,
    this.planetMass,
    this.planetRadius,
    this.planetOrbitPeriod,
    this.orbitalDistance,
    this.eccentricity,
    required this.discoveryMethod,
    required this.facility,
    this.discoveryYear,
    this.publicationDate,
    this.starId,
    this.starDistance,
    this.starMagnitude,
    this.featuredMediaId,
    this.featuredImageUrl,
    required this.link,
    this.eyesOnExoplanetsUrl,
    this.planetSizeClass,
    this.isKepler,
    this.multiPlanetSystem,
  });

  factory NASAExoplanetData.fromJson(Map<String, dynamic> json) {
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    // Extract featured image URL
    String? imageUrl;
    if (json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;
      if (embedded['wp:featuredmedia'] != null) {
        final media = embedded['wp:featuredmedia'] as List;
        if (media.isNotEmpty) {
          imageUrl = media[0]['source_url'] as String?;
        }
      }
    }

    // Build Eyes on Exoplanets URL
    final exoId = acf['exo_id'] as String?;
    String? eyesUrl;
    if (exoId != null) {
      eyesUrl = 'https://eyes.nasa.gov/apps/exo/#/planet/$exoId';
    }

    return NASAExoplanetData(
      id: json['id'] as int,
      slug: json['slug'] as String,
      displayName:
          acf['display_name'] as String? ?? json['title']['rendered'] as String,
      subtitle: acf['subtitle'] as String?,
      description:
          acf['derived_description'] as String? ??
          json['excerpt']['rendered'] as String? ??
          '',
      shortDescription: acf['short_description'] as String?,
      planetType: acf['planet_type'] as String? ?? 'Unknown',
      planetMass: acf['planet_mass'] as String?,
      planetRadius: acf['planet_radius'] as String?,
      planetOrbitPeriod: acf['period_display'] as String?,
      orbitalDistance: (acf['pl_orbsmax'] as num?)?.toDouble(),
      eccentricity: acf['eccentricity'] as String?,
      discoveryMethod: acf['pl_discmethod'] as String? ?? 'Unknown',
      facility: acf['pl_facility'] as String? ?? 'Unknown',
      discoveryYear: acf['pl_disc'] as int?,
      publicationDate: acf['pl_publ_date'] as String?,
      starId: acf['star_id'] as int?,
      starDistance: (acf['st_dist'] as num?)?.toDouble(),
      starMagnitude: acf['st_optmag'] as String?,
      featuredMediaId: json['featured_media'] as int?,
      featuredImageUrl: imageUrl,
      link: json['link'] as String,
      eyesOnExoplanetsUrl: eyesUrl,
      planetSizeClass: acf['planet_size_class'] as String?,
      isKepler: acf['pl_kepflag'] as bool?,
      multiPlanetSystem: acf['multiple_planet_system'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'displayName': displayName,
      'subtitle': subtitle,
      'description': description,
      'shortDescription': shortDescription,
      'planetType': planetType,
      'planetMass': planetMass,
      'planetRadius': planetRadius,
      'planetOrbitPeriod': planetOrbitPeriod,
      'orbitalDistance': orbitalDistance,
      'eccentricity': eccentricity,
      'discoveryMethod': discoveryMethod,
      'facility': facility,
      'discoveryYear': discoveryYear,
      'publicationDate': publicationDate,
      'starId': starId,
      'starDistance': starDistance,
      'starMagnitude': starMagnitude,
      'featuredMediaId': featuredMediaId,
      'featuredImageUrl': featuredImageUrl,
      'link': link,
      'eyesOnExoplanetsUrl': eyesOnExoplanetsUrl,
      'planetSizeClass': planetSizeClass,
      'isKepler': isKepler,
      'multiPlanetSystem': multiPlanetSystem,
    };
  }
}
