import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import '../models/planet.dart';

/// AI Enhancement Service for 3D Planet Viewer
///
/// Architecture:
/// 1. Check IndexedDB cache for existing AI code
/// 2. If cached: Return immediately
/// 3. If not cached: Call OpenRouter API
/// 4. Store generated code in IndexedDB
/// 5. Return code to be injected into existing 3D viewer
class AIEnhancementService {
  static const String _dbName = 'AstroSynthAICache';
  static const String _cacheStoreName = 'ai_planet_code_cache';
  static const int _dbVersion = 1;

  dynamic _db;
  bool _isInitialized = false;

  /// Initialize IndexedDB for caching AI-generated code
  Future<void> initialize() async {
    if (_isInitialized && _db != null) return;

    try {
      // Open database - returns Future<Database> directly
      _db = await html.window.indexedDB!.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: (event) {
          final db = event.target.result as dynamic;

          // Create object store for AI-generated code
          if (!db.objectStoreNames!.contains(_cacheStoreName)) {
            db.createObjectStore(_cacheStoreName, keyPath: 'planetName');
            print('[AI-CACHE] Created AI code cache store');
          }
        },
      );

      _isInitialized = true;
      print('[AI-CACHE] ✅ Initialized successfully');
    } catch (e) {
      print('[AI-CACHE] ❌ Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Get AI enhancement code for a planet (cache-first)
  Future<AIEnhancementResult> getEnhancementCode(
    Planet planet,
    String biomeType,
  ) async {
    await initialize();

    final planetKey = planet.name;

    // Try cache first
    final cached = await _getCachedCode(planetKey);
    if (cached != null) {
      print('[AI-CACHE] ✅ Using cached code for: $planetKey');
      return AIEnhancementResult(
        code: cached,
        fromCache: true,
        timestamp: DateTime.now(),
      );
    }

    // Generate new if not cached
    print('[AI-ENHANCE] 🤖 Generating new enhancement for: $planetKey');
    final code = await _generateEnhancementCode(planet, biomeType);

    if (code != null) {
      await _cacheCode(planetKey, code);
      return AIEnhancementResult(
        code: code,
        fromCache: false,
        timestamp: DateTime.now(),
      );
    }

    throw Exception('Failed to generate AI enhancement');
  }

  /// Get cached code for a planet
  Future<String?> _getCachedCode(String planetKey) async {
    if (_db == null) return null;

    try {
      final transaction = _db!.transaction(_cacheStoreName, 'readonly');
      final store = transaction.objectStore(_cacheStoreName);

      // getObject() returns Future directly
      final data = await store.getObject(planetKey);

      if (data != null) {
        // Convert to proper Map<String, dynamic>
        final result = <String, dynamic>{};
        (data as Map).forEach((key, value) {
          result[key.toString()] = value;
        });
        return result['code'] as String?;
      }
    } catch (e) {
      print('[AI-CACHE] Error reading cache: $e');
    }

    return null;
  }

  /// Cache generated code for a planet
  Future<void> _cacheCode(String planetKey, String code) async {
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_cacheStoreName, 'readwrite');
      final store = transaction.objectStore(_cacheStoreName);

      await store.put({
        'planetName': planetKey,
        'code': code,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await transaction.completed;
      print('[AI-CACHE] ✅ Cached code for: $planetKey');
    } catch (e) {
      print('[AI-CACHE] ❌ Error caching code: $e');
    }
  }

  /// Generate AI enhancement code using OpenRouter API
  Future<String?> _generateEnhancementCode(
    Planet planet,
    String biomeType,
  ) async {
    const apiKey =
        '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';
    const model = 'openai/gpt-4o-mini';
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

    try {
      final prompt = _buildEnhancementPrompt(planet, biomeType);

      print('[AI-ENHANCE] 📤 Sending request to OpenRouter...');
      print('[AI-ENHANCE] Planet: ${planet.name}');
      print('[AI-ENHANCE] Biome: $biomeType');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://astrosynth.app',
          'X-Title': 'AstroSynth AI Enhancement',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert Three.js developer specializing in 3D space visualization. Generate ONLY valid JavaScript code for enhancing existing planet renders. No explanations, no markdown, just executable code.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['choices'][0]['message']['content'] as String;

        print(
          '[AI-ENHANCE] ✅ Generated ${code.length} chars of enhancement code',
        );
        return _cleanGeneratedCode(code);
      } else {
        print('[AI-ENHANCE] ❌ API error: ${response.statusCode}');
        print('[AI-ENHANCE] Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[AI-ENHANCE] ❌ Generation error: $e');
      return null;
    }
  }

  /// Build enhancement prompt (not full generation)
  String _buildEnhancementPrompt(Planet planet, String biomeType) {
    return '''
Generate JavaScript code to ENHANCE the existing 3D planet rendering.
The base planet sphere already exists. Add these enhancements:

PLANET DATA:
- Name: ${planet.name}
- Biome: $biomeType
- Temperature: ${planet.equilibriumTemperature?.toStringAsFixed(0) ?? 'N/A'}K
- Mass: ${planet.mass?.toStringAsFixed(2) ?? 'N/A'} Earth masses
- Radius: ${planet.radius?.toStringAsFixed(2) ?? 'N/A'} Earth radii
- Distance from Star: ${planet.semiMajorAxis?.toStringAsFixed(2) ?? 'N/A'} AU

REQUIREMENTS:
1. Create a function: function enhancePlanet(scene, planetMesh) { }
2. Add atmospheric effects (glow, clouds if applicable)
3. Add surface details (craters, features based on biome)
4. Add special effects (gas bands, auroras, lava flows)
5. Return the modified scene/mesh

BIOME GUIDELINES:
- Desert: Sandy textures, dust clouds
- Ocean: Water shader, wave effects, mist
- Rocky: Craters, mountains, rough terrain
- Ice: Frost effects, ice caps, crystalline features
- Gas Giant: Bands, storms, swirling patterns
- Lava: Glowing cracks, heat shimmer
- Volcanic: Eruption effects, ash clouds
- Tropical: Green hues, cloud systems
- Barren: Stark, minimal effects

CODE CONSTRAINTS:
- Use only Three.js built-in materials and geometries
- Keep code under 2000 characters
- No external dependencies
- Modify existing planetMesh, don't create new planet
- Return the enhanced scene

OUTPUT FORMAT:
```javascript
function enhancePlanet(scene, planetMesh) {
  // Your enhancement code here
  return scene;
}
```

CRITICAL: Return ONLY the JavaScript code, no explanations.
''';
  }

  /// Clean generated code (remove markdown formatting)
  String _cleanGeneratedCode(String code) {
    // Remove markdown code blocks
    var cleaned = code
        .replaceAll('```javascript', '')
        .replaceAll('```js', '')
        .replaceAll('```', '');

    // Trim whitespace
    cleaned = cleaned.trim();

    // Ensure it has the enhancePlanet function
    if (!cleaned.contains('function enhancePlanet')) {
      print('[AI-ENHANCE] ⚠️ Generated code missing enhancePlanet function');
    }

    return cleaned;
  }

  /// Clear all cached AI code (for debugging)
  Future<void> clearCache() async {
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_cacheStoreName, 'readwrite');
      final store = transaction.objectStore(_cacheStoreName);
      await store.clear();

      await transaction.completed;
      print('[AI-CACHE] 🗑️ Cleared all cached code');
    } catch (e) {
      print('[AI-CACHE] ❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_db == null) return {'cached': 0, 'error': 'Database not initialized'};

    try {
      final transaction = _db!.transaction(_cacheStoreName, 'readonly');
      final store = transaction.objectStore(_cacheStoreName);

      // count() returns Future<int> directly
      final count = await store.count() as int;

      return {
        'cached': count,
        'storeName': _cacheStoreName,
        'initialized': _isInitialized,
      };
    } catch (e) {
      return {'cached': 0, 'error': e.toString()};
    }
  }
}

/// Result of AI enhancement code generation
class AIEnhancementResult {
  final String code;
  final bool fromCache;
  final DateTime timestamp;

  AIEnhancementResult({
    required this.code,
    required this.fromCache,
    required this.timestamp,
  });
}
