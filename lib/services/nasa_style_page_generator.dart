import '../models/planet.dart';
import 'nasa_exoplanet_api_service.dart';

/// Generates NASA-style exoplanet pages for any planet
///
/// Creates beautiful, interactive HTML pages similar to NASA's official
/// exoplanet catalog, with embedded 3D viewer, discovery info, and statistics.
class NASAStylePageGenerator {
  final NASAExoplanetAPIService _nasaService = NASAExoplanetAPIService();

  /// Generate complete HTML page for a planet
  ///
  /// Combines our JSON data with optional NASA API enhancement
  /// to create a professional, interactive planet page.
  Future<String> generatePlanetPage(
    Planet planet, {
    bool fetchNASAData = true,
  }) async {
    print('[PAGE-GEN] Generating page for: ${planet.name}');

    // Try to fetch NASA data for enhancement
    NASAExoplanetData? nasaData;
    if (fetchNASAData) {
      try {
        nasaData = await _nasaService.getExoplanetByName(planet.name);
        if (nasaData != null) {
          print('[PAGE-GEN] ✅ Enhanced with NASA data');
        }
      } catch (e) {
        print('[PAGE-GEN] ⚠️ NASA data not available: $e');
      }
    }

    return _buildHTML(planet, nasaData);
  }

  /// Build the complete HTML page
  String _buildHTML(Planet planet, NASAExoplanetData? nasaData) {
    // Use NASA data if available, fallback to our JSON
    final displayName = nasaData?.displayName ?? planet.name;
    final planetType = nasaData?.planetType ?? _inferPlanetType(planet);
    final description = nasaData?.description ?? _generateDescription(planet);
    final mass =
        nasaData?.planetMass ??
        '${planet.mass?.toStringAsFixed(2) ?? 'Unknown'} Earth masses';
    final radius =
        nasaData?.planetRadius ??
        '${planet.radius?.toStringAsFixed(2) ?? 'Unknown'} Earth radii';
    final period =
        nasaData?.planetOrbitPeriod ??
        '${planet.orbitalPeriod?.toStringAsFixed(1) ?? 'Unknown'} days';
    final distance =
        nasaData?.orbitalDistance?.toStringAsFixed(3) ??
        planet.semiMajorAxis?.toStringAsFixed(3) ??
        'Unknown';
    final discoveryMethod = nasaData?.discoveryMethod ?? 'Unknown';
    final facility = nasaData?.facility ?? 'Unknown';
    final discoveryYear =
        nasaData?.discoveryYear?.toString() ??
        planet.discoveryYear?.toString() ??
        'Unknown';
    final starDistance =
        nasaData?.starDistance?.toString() ??
        planet.distanceFromEarth?.toString() ??
        'Unknown';
    final sizeClass = nasaData?.planetSizeClass ?? planetType;

    // Format planet name for Eyes on Exoplanets URL
    final exoId = _formatExoId(planet.name);
    final eyesURL =
        nasaData?.eyesOnExoplanetsUrl ??
        'https://eyes.nasa.gov/apps/exo/#/planet/$exoId';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$displayName - Exoplanet Explorer</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0B3D91 0%, #000428 100%);
            color: white;
            min-height: 100vh;
        }

        .header {
            background: rgba(11, 61, 145, 0.9);
            padding: 20px;
            text-align: center;
            border-bottom: 3px solid #FC3D21;
            box-shadow: 0 4px 20px rgba(0,0,0,0.5);
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }

        .planet-type {
            display: inline-block;
            background: #FC3D21;
            padding: 8px 20px;
            border-radius: 20px;
            font-weight: bold;
            margin-top: 10px;
        }

        .nasa-badge {
            display: inline-block;
            background: #4CAF50;
            padding: 5px 15px;
            border-radius: 15px;
            font-size: 0.8em;
            margin-left: 10px;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 40px 20px;
        }

        .planet-viewer {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 40px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .planet-viewer iframe {
            width: 100%;
            height: 600px;
            border: none;
            border-radius: 10px;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }

        .info-card {
            background: rgba(255, 255, 255, 0.08);
            padding: 25px;
            border-radius: 12px;
            border-left: 4px solid #FC3D21;
            backdrop-filter: blur(10px);
            transition: transform 0.3s, box-shadow 0.3s;
        }

        .info-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(252, 61, 33, 0.3);
        }

        .info-card h3 {
            color: #FC3D21;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 10px;
        }

        .info-card .value {
            font-size: 1.8em;
            font-weight: bold;
            color: white;
        }

        .description-section {
            background: rgba(255, 255, 255, 0.08);
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 40px;
            backdrop-filter: blur(10px);
            line-height: 1.8;
        }

        .description-section h2 {
            color: #FC3D21;
            margin-bottom: 15px;
            font-size: 1.8em;
        }

        .stats-section {
            background: rgba(11, 61, 145, 0.3);
            padding: 30px;
            border-radius: 12px;
            margin-bottom: 40px;
        }

        .stats-section h2 {
            color: #FC3D21;
            margin-bottom: 20px;
            font-size: 1.8em;
        }

        .stat-row {
            display: flex;
            justify-content: space-between;
            padding: 15px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }

        .stat-row:last-child {
            border-bottom: none;
        }

        .stat-label {
            color: rgba(255, 255, 255, 0.7);
            font-weight: 500;
        }

        .stat-value {
            color: white;
            font-weight: bold;
        }

        .related-topics {
            background: rgba(255, 255, 255, 0.05);
            padding: 40px;
            border-radius: 12px;
            backdrop-filter: blur(10px);
        }

        .related-topics h2 {
            color: white;
            margin-bottom: 30px;
            font-size: 2em;
        }

        .topics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }

        .topic-card {
            background: linear-gradient(135deg, rgba(11, 61, 145, 0.8) 0%, rgba(252, 61, 33, 0.6) 100%);
            padding: 30px;
            border-radius: 10px;
            text-decoration: none;
            color: white;
            transition: transform 0.3s, box-shadow 0.3s;
            display: block;
        }

        .topic-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 10px 30px rgba(252, 61, 33, 0.4);
        }

        .topic-card h3 {
            font-size: 1.4em;
            margin-bottom: 10px;
        }

        .planet-visual {
            width: 100%;
            height: 300px;
            background: ${_getPlanetGradient(planetType)};
            border-radius: 50%;
            margin: 30px auto;
            box-shadow: 0 20px 60px ${_getPlanetGlow(planetType)}, inset -20px -20px 50px rgba(0,0,0,0.5);
            animation: rotate 20s linear infinite;
            position: relative;
            max-width: 300px;
        }

        @keyframes rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .planet-visual::after {
            content: '';
            position: absolute;
            top: 20%;
            left: 20%;
            width: 60%;
            height: 60%;
            background: radial-gradient(circle, rgba(255,255,255,0.3) 0%, transparent 70%);
            border-radius: 50%;
        }

        @media (max-width: 768px) {
            .header h1 {
                font-size: 1.8em;
            }

            .info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>$displayName</h1>
        <span class="planet-type">$planetType</span>
        ${nasaData != null ? '<span class="nasa-badge">✓ NASA Verified</span>' : ''}
    </div>

    <div class="container">
        <!-- Planet Visual Representation -->
        <div class="planet-viewer">
            <div class="planet-visual"></div>
            <p style="text-align: center; margin-top: 20px; opacity: 0.8;">
                Artist's representation of a $planetType exoplanet
            </p>
        </div>

        <!-- Interactive 3D Viewer -->
        <div class="planet-viewer">
            <h2 style="margin-bottom: 20px; color: #FC3D21;">Explore in 3D</h2>
            <iframe
                src="$eyesURL"
                title="NASA Eyes on Exoplanets - $displayName"
                allow="fullscreen"
                loading="lazy">
            </iframe>
        </div>

        <!-- Key Information Cards -->
        <div class="info-grid">
            <div class="info-card">
                <h3>Planet Mass</h3>
                <div class="value">$mass</div>
            </div>
            <div class="info-card">
                <h3>Planet Radius</h3>
                <div class="value">$radius</div>
            </div>
            <div class="info-card">
                <h3>Orbital Period</h3>
                <div class="value">$period</div>
            </div>
            <div class="info-card">
                <h3>Distance from Star</h3>
                <div class="value">$distance AU</div>
            </div>
        </div>

        <!-- Description -->
        <div class="description-section">
            <h2>About This Exoplanet</h2>
            <p>$description</p>
        </div>

        <!-- Detailed Statistics -->
        <div class="stats-section">
            <h2>Discovery & Observation Details</h2>
            <div class="stat-row">
                <span class="stat-label">Discovery Method</span>
                <span class="stat-value">$discoveryMethod</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Discovery Facility</span>
                <span class="stat-value">$facility</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Discovery Year</span>
                <span class="stat-value">$discoveryYear</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Host Star Distance</span>
                <span class="stat-value">$starDistance light-years</span>
            </div>
            <div class="stat-row">
                <span class="stat-label">Planet Size Class</span>
                <span class="stat-value">$sizeClass</span>
            </div>
        </div>

        <!-- Related Topics -->
        <div class="related-topics">
            <h2>Discover More Topics From NASA</h2>
            <div class="topics-grid">
                <a href="https://science.nasa.gov/universe/search-for-life/" class="topic-card" target="_blank">
                    <h3>🔭 Search for Life</h3>
                    <p>Exploring the possibility of life beyond Earth</p>
                </a>
                <a href="https://science.nasa.gov/universe/stars/" class="topic-card" target="_blank">
                    <h3>⭐ Stars</h3>
                    <p>Understanding stellar systems and their planets</p>
                </a>
                <a href="https://science.nasa.gov/universe/" class="topic-card" target="_blank">
                    <h3>🌌 Universe</h3>
                    <p>Exploring the cosmos and its mysteries</p>
                </a>
                <a href="https://science.nasa.gov/universe/black-holes/" class="topic-card" target="_blank">
                    <h3>🕳️ Black Holes</h3>
                    <p>The most extreme objects in the universe</p>
                </a>
            </div>
        </div>
    </div>

    <script>
        console.log("Planet Page Loaded: $displayName");
        console.log("Planet Type: $planetType");
        console.log("NASA Data: ${nasaData != null ? 'Available' : 'Not Available'}");
    </script>
</body>
</html>''';
  }

  /// Infer planet type from our JSON data
  String _inferPlanetType(Planet planet) {
    final mass = planet.mass ?? 0;
    final radius = planet.radius ?? 0;

    if (mass > 100 || radius > 10) {
      return 'Gas Giant';
    } else if (mass > 50 || radius > 4) {
      return 'Neptune-like';
    } else if (mass > 2 || radius > 1.5) {
      return 'Super Earth';
    } else {
      return 'Terrestrial';
    }
  }

  /// Generate description if NASA data not available
  String _generateDescription(Planet planet) {
    final type = _inferPlanetType(planet);
    final mass = planet.mass?.toStringAsFixed(2) ?? 'unknown';
    final period = planet.orbitalPeriod?.toStringAsFixed(1) ?? 'unknown';
    final distance = planet.semiMajorAxis?.toStringAsFixed(3) ?? 'unknown';

    return '${planet.name} is a $type exoplanet. Its mass is $mass Earth masses, '
        'it takes $period days to complete one orbit of its star, and is $distance AU from its star.';
  }

  /// Format planet name for Eyes on Exoplanets URL
  String _formatExoId(String name) {
    // Replace spaces with underscores
    return name.replaceAll(' ', '_');
  }

  /// Get CSS gradient for planet type
  String _getPlanetGradient(String type) {
    switch (type.toLowerCase()) {
      case 'gas giant':
        return 'radial-gradient(circle at 30% 30%, #f4a460, #cd853f, #8b4513)';
      case 'neptune-like':
        return 'radial-gradient(circle at 30% 30%, #4a90e2, #0B3D91, #000428)';
      case 'super earth':
        return 'radial-gradient(circle at 30% 30%, #228B22, #006400, #004d00)';
      case 'terrestrial':
        return 'radial-gradient(circle at 30% 30%, #8B4513, #654321, #3d2817)';
      default:
        return 'radial-gradient(circle at 30% 30%, #4a90e2, #0B3D91, #000428)';
    }
  }

  /// Get CSS glow color for planet type
  String _getPlanetGlow(String type) {
    switch (type.toLowerCase()) {
      case 'gas giant':
        return 'rgba(244, 164, 96, 0.5)';
      case 'neptune-like':
        return 'rgba(74, 144, 226, 0.5)';
      case 'super earth':
        return 'rgba(34, 139, 34, 0.5)';
      case 'terrestrial':
        return 'rgba(139, 69, 19, 0.5)';
      default:
        return 'rgba(74, 144, 226, 0.5)';
    }
  }

  /// Save generated HTML to file (for web deployment)
  Future<void> saveToFile(String html, String filename) async {
    // In web context, this would trigger a download
    // For now, just log
    print('[PAGE-GEN] Generated HTML (${html.length} chars)');
    print('[PAGE-GEN] Filename: $filename');
  }
}
