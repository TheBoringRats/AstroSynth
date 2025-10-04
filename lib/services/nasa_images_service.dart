import 'dart:convert';

import 'package:http/http.dart' as http;

/// NASA Images and Video Library API Service
/// Fetches real NASA images for planets and astronomical objects
/// API Documentation: https://images.nasa.gov/docs/images.nasa.gov_api_docs.pdf
class NASAImagesService {
  static final NASAImagesService _instance = NASAImagesService._internal();
  factory NASAImagesService() => _instance;
  NASAImagesService._internal();

  final http.Client _client = http.Client();

  // NASA Images API endpoint (no API key required for images.nasa.gov)
  // Note: NASA API key is available if needed for other NASA APIs
  static const String _baseUrl = 'https://images-api.nasa.gov/search';

  // Cache for image URLs
  final Map<String, List<NASAImage>> _imageCache = {};

  /// Search for images related to a planet or astronomical object
  /// Returns a list of NASAImage objects with URLs and metadata
  Future<List<NASAImage>> searchImages(
    String query, {
    int limit = 10,
    String mediaType = 'image',
    int? yearStart,
  }) async {
    // Check cache first
    final cacheKey = '$query-$limit-$mediaType-$yearStart';
    if (_imageCache.containsKey(cacheKey)) {
      print('📦 Using cached images for: $query');
      return _imageCache[cacheKey]!;
    }

    print('🔍 Searching NASA images for: $query');

    try {
      // Build query parameters
      final queryParams = {
        'q': query,
        'media_type': mediaType,
        if (yearStart != null) 'year_start': yearStart.toString(),
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout after 10 seconds');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final collection = data['collection'];

        if (collection == null || collection['items'] == null) {
          print('⚠️ No items found in NASA images response');
          return [];
        }

        final items = collection['items'] as List;
        final images = <NASAImage>[];

        for (var item in items.take(limit)) {
          try {
            final imageData = item['data']?[0];
            final links = item['links'];

            if (imageData != null && links != null && links.isNotEmpty) {
              final image = NASAImage(
                title: imageData['title'] ?? 'Untitled',
                description: imageData['description'] ?? '',
                nasaId: imageData['nasa_id'] ?? '',
                dateCreated: imageData['date_created'] ?? '',
                thumbnailUrl: links[0]['href'] ?? '',
                keywords:
                    (imageData['keywords'] as List?)
                        ?.map((k) => k.toString())
                        .toList() ??
                    [],
                center: imageData['center'] ?? '',
                photographer:
                    imageData['photographer'] ??
                    imageData['secondary_creator'] ??
                    '',
              );
              images.add(image);
            }
          } catch (e) {
            print('⚠️ Error parsing image item: $e');
            continue;
          }
        }

        // Cache results
        _imageCache[cacheKey] = images;
        print('✅ Found ${images.length} images for: $query');
        return images;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ NASA Images API error: $e');
      return [];
    }
  }

  /// Search for exoplanet images
  /// Uses various search terms to find relevant images
  Future<List<NASAImage>> searchExoplanetImages(String planetName) async {
    // Try multiple search strategies
    final queries = [
      planetName, // Direct planet name
      planetName.replaceAll('-', ' '), // Planet name with spaces
      'exoplanet ${planetName.split('-')[0]}', // Exoplanet + system name
      'exoplanet discovery', // Generic exoplanet images
      'alien planet', // Artist renditions
    ];

    for (var query in queries) {
      final images = await searchImages(query, limit: 5, yearStart: 2000);
      if (images.isNotEmpty) {
        return images;
      }
    }

    // Fallback to generic exoplanet images
    return await searchImages('exoplanet', limit: 5, yearStart: 2000);
  }

  /// Search for host star images
  Future<List<NASAImage>> searchStarImages(String starName) async {
    final queries = [starName, '$starName star', 'star system $starName'];

    for (var query in queries) {
      final images = await searchImages(query, limit: 5);
      if (images.isNotEmpty) {
        return images;
      }
    }

    // Fallback to generic star images
    return await searchImages('star', limit: 5, yearStart: 2000);
  }

  /// Get high-resolution image URL from asset manifest
  /// NASA provides a manifest.json with different resolutions
  Future<String?> getHighResolutionUrl(String nasaId) async {
    try {
      final manifestUrl = 'https://images-api.nasa.gov/asset/$nasaId';
      final response = await _client.get(Uri.parse(manifestUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final collection = data['collection'];

        if (collection != null && collection['items'] != null) {
          final items = collection['items'] as List;

          // Find largest image (usually last in list)
          for (var item in items.reversed) {
            final href = item['href'];
            if (href != null && href.toString().contains('.jpg')) {
              return href.toString();
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Error fetching high-res image: $e');
    }
    return null;
  }

  /// Clear image cache
  void clearCache() {
    _imageCache.clear();
    print('🗑️ NASA images cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int totalImages = 0;
    for (var images in _imageCache.values) {
      totalImages += images.length;
    }

    return {
      'cachedQueries': _imageCache.length,
      'totalCachedImages': totalImages,
    };
  }
}

/// Model class for NASA Image data
class NASAImage {
  final String title;
  final String description;
  final String nasaId;
  final String dateCreated;
  final String thumbnailUrl;
  final List<String> keywords;
  final String center;
  final String photographer;

  NASAImage({
    required this.title,
    required this.description,
    required this.nasaId,
    required this.dateCreated,
    required this.thumbnailUrl,
    required this.keywords,
    required this.center,
    required this.photographer,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'nasaId': nasaId,
    'dateCreated': dateCreated,
    'thumbnailUrl': thumbnailUrl,
    'keywords': keywords,
    'center': center,
    'photographer': photographer,
  };

  factory NASAImage.fromJson(Map<String, dynamic> json) => NASAImage(
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    nasaId: json['nasaId'] ?? '',
    dateCreated: json['dateCreated'] ?? '',
    thumbnailUrl: json['thumbnailUrl'] ?? '',
    keywords:
        (json['keywords'] as List?)?.map((k) => k.toString()).toList() ?? [],
    center: json['center'] ?? '',
    photographer: json['photographer'] ?? '',
  );

  @override
  String toString() => 'NASAImage(title: $title, nasaId: $nasaId)';
}
