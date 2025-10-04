import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/planet.dart';

/// Service for generating AI-powered 3D planet visualizations using OpenRouter API
/// Architecture: NASA Data -> LLM -> Three.js Code -> Dynamic Rendering
class AIPlanetGeneratorService {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _apiKey =
      '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';
  static const String _model =
      'openai/gpt-4o-mini'; // Use GPT-4 for better code generation

  /// Generate Three.js code for planet visualization using AI
  ///
  /// Takes real NASA exoplanet data and generates custom Three.js visualization code
  /// that will be dynamically executed in an iframe.
  ///
  /// Returns:
  /// - `threeJsCode`: Complete Three.js code as string
  /// - `null`: If generation fails
  Future<String?> generatePlanetVisualization(
    Planet planet,
    String biomeType,
  ) async {
    try {
      print('[AI-GEN] Starting AI generation for: ${planet.name}');

      // Prepare comprehensive planet data for the LLM
      final planetData = _preparePlanetData(planet, biomeType);

      // Build the prompt
      final prompt = _buildVisualizationPrompt(planetData);

      // Call OpenRouter API
      final response = await _callOpenRouterAPI(prompt);

      if (response != null) {
        print('[AI-GEN] ✅ Successfully generated Three.js code');
        print('[AI-GEN] Code length: ${response.length} characters');
        return response;
      } else {
        print('[AI-GEN] ❌ Failed to generate code');
        return null;
      }
    } catch (e) {
      print('[AI-GEN] ❌ Error: $e');
      return null;
    }
  }

  /// Prepare structured planet data for LLM
  Map<String, dynamic> _preparePlanetData(Planet planet, String biomeType) {
    return {
      // Basic identification
      'name': planet.name,
      'hostStar': planet.hostStarName,
      'discoveryYear': planet.discoveryYear,
      'discoveryMethod': planet.discoveryMethod,

      // Physical properties
      'mass': planet.mass, // Earth masses
      'radius': planet.radius, // Earth radii
      'temperature': planet.equilibriumTemperature, // Kelvin
      'density': planet.mass != null && planet.radius != null
          ? planet.mass! / (planet.radius! * planet.radius! * planet.radius!)
          : null,

      // Orbital characteristics
      'orbitalPeriod': planet.orbitalPeriod, // days
      'semiMajorAxis': planet.semiMajorAxis, // AU
      'eccentricity': planet.eccentricity,

      // Stellar properties (host star)
      'stellarType': planet.stellarSpectralType,
      'stellarTemperature': planet.stellarTemperature, // Kelvin
      'stellarRadius': planet.stellarRadius, // Solar radii
      'stellarMass': planet.stellarMass, // Solar masses
      // Classification (derived)
      'biome': biomeType,
      'classification': _classifyPlanet(planet),
      'habitability': planet.habitabilityScore,

      // Derived properties
      'surfaceGravity': planet.mass != null && planet.radius != null
          ? planet.mass! / (planet.radius! * planet.radius!)
          : null,
      'escapeVelocity': planet.mass != null && planet.radius != null
          ? 11.2 * math.sqrt(planet.mass! / planet.radius!)
          : null, // km/s
      'isTidallyLocked': _isTidallyLocked(planet),
      'hasRings': _mightHaveRings(planet),
      'atmosphereType': _inferAtmosphere(planet, biomeType),
    };
  }

  /// Build the AI prompt with NASA data
  String _buildVisualizationPrompt(Map<String, dynamic> planetData) {
    return '''
You are an expert astrophysics visualizer and Three.js developer.

TASK: Generate a complete, self-contained Three.js visualization for the following exoplanet.

PLANET DATA (NASA Exoplanet Archive):
${JsonEncoder.withIndent('  ').convert(planetData)}

REQUIREMENTS:
1. Generate COMPLETE, EXECUTABLE Three.js code (not pseudocode)
2. Use realistic astrophysical scaling:
   - Planet radius in Earth radii: ${planetData['radius'] ?? 1.0}
   - Star luminosity based on spectral type: ${planetData['stellarType'] ?? 'G2V'}
   - Surface temperature: ${planetData['temperature'] ?? 285}K
3. Visual features MUST match the data:
   - Biome type: ${planetData['biome']}
   - Planet classification: ${planetData['classification']}
   - Temperature-based coloring (hot=red, cold=blue, temperate=Earth-like)
4. Include:
   - Procedural surface textures (use noise functions)
   - Atmosphere glow (if applicable)
   - Cloud layer (for suitable planets)
   - Rings (for gas giants if indicated)
   - Realistic lighting from host star
   - Rotation animation
5. Code structure:
   - Assume Three.js is already loaded globally
   - Scene, camera, renderer already exist (use global `scene`, `camera`, `renderer`)
   - Return only the planet generation function
   - Function name: generateAIPlanet()

OUTPUT FORMAT:
Return ONLY the JavaScript code, no markdown, no explanations.
Start with: function generateAIPlanet() {
End with: }

The function should:
1. Remove any existing planet objects from scene
2. Create the planet mesh with procedural textures
3. Add atmosphere, clouds, rings if applicable
4. Add to scene
5. Position camera appropriately
6. Return the planet object

CRITICAL: Code must be production-ready and executable immediately.
''';
  }

  /// Call OpenRouter API
  Future<String?> _callOpenRouterAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://astrosynth.app', // Optional: for rankings
          'X-Title': 'AstroSynth', // Optional: shows in OpenRouter dashboard
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are an expert Three.js developer and astrophysics visualizer. Generate clean, production-ready code.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 4000, // Enough for complete Three.js code
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedCode =
            data['choices'][0]['message']['content'] as String;

        // Clean up the response (remove markdown code blocks if present)
        String cleanedCode = generatedCode.trim();
        if (cleanedCode.startsWith('```javascript') ||
            cleanedCode.startsWith('```js')) {
          cleanedCode = cleanedCode.substring(cleanedCode.indexOf('\n') + 1);
        }
        if (cleanedCode.endsWith('```')) {
          cleanedCode = cleanedCode.substring(
            0,
            cleanedCode.lastIndexOf('```'),
          );
        }

        return cleanedCode.trim();
      } else {
        print('[AI-GEN] API Error: ${response.statusCode}');
        print('[AI-GEN] Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('[AI-GEN] Network error: $e');
      return null;
    }
  }

  // Helper methods for planet classification

  String _classifyPlanet(Planet planet) {
    final mass = planet.mass ?? 1.0;
    final radius = planet.radius ?? 1.0;
    final temp = planet.equilibriumTemperature ?? 285;

    if (mass > 10) return 'Gas Giant (Jupiter-like)';
    if (mass > 3) return 'Ice Giant (Neptune-like)';
    if (temp > 1000) return 'Hot Rocky World (Lava Planet)';
    if (temp < 150) return 'Ice World (Frozen)';
    if (radius > 1.5 && mass < 5) return 'Super-Earth (Ocean World)';
    if (radius > 0.5 && radius < 1.5) return 'Rocky Terrestrial';
    return 'Terrestrial Planet';
  }

  bool _isTidallyLocked(Planet planet) {
    final period = planet.orbitalPeriod ?? 365;
    return period < 50; // Close-in planets are usually tidally locked
  }

  bool _mightHaveRings(Planet planet) {
    final mass = planet.mass ?? 1.0;
    return mass > 5; // Gas/ice giants often have rings
  }

  String _inferAtmosphere(Planet planet, String biomeType) {
    final temp = planet.equilibriumTemperature ?? 285;
    final mass = planet.mass ?? 1.0;

    if (mass > 10) return 'Hydrogen-Helium (thick)';
    if (mass > 3) return 'Hydrogen-Helium-Methane (thick)';
    if (temp > 1000) return 'Silicate vapor / None';
    if (temp < 150) return 'Nitrogen-Methane (thin)';
    if (biomeType.toLowerCase().contains('ocean'))
      return 'Nitrogen-Oxygen-Water vapor';
    if (mass < 0.5) return 'Thin or None';
    return 'Nitrogen-Carbon dioxide';
  }
}
