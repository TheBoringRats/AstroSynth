import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../models/biome.dart';
import '../models/planet.dart';
import '../services/ai_enhancement_service.dart';

/// Interactive 3D planet world viewer using Three.js
///
/// Features:
/// - Full 3D procedurally generated terrain
/// - Biome-specific landscape generation
/// - Free camera movement (WASD controls)
/// - Day/night cycle toggle
/// - Dynamic terrain regeneration
/// - Planet data-driven generation (temperature, gravity, atmosphere)
class Planet3DWorldViewer extends StatefulWidget {
  final Planet planet;
  final Biome biome;

  const Planet3DWorldViewer({
    super.key,
    required this.planet,
    required this.biome,
  });

  @override
  State<Planet3DWorldViewer> createState() => _Planet3DWorldViewerState();
}

class _Planet3DWorldViewerState extends State<Planet3DWorldViewer> {
  late String viewId;
  bool _isLoading = true;
  bool _isEnhancing = false;
  String _enhancementStatus = '';
  final _enhancementService = AIEnhancementService();

  @override
  void initState() {
    super.initState();
    viewId = 'planet-3d-viewer-${DateTime.now().millisecondsSinceEpoch}';
    _registerIframe();

    // Wait a bit for iframe to load, then send planet data and enhancements
    Future.delayed(const Duration(milliseconds: 1500), () {
      _sendPlanetData();
      _applyAIEnhancements();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _registerIframe() {
    // Register the iframe view factory
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'planet_3d_viewer.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents =
            'auto'; // Allow iframe to receive pointer events

      return iframe;
    });
  }

  void _sendPlanetData() {
    // Prepare comprehensive planet data for scientifically accurate Three.js rendering
    final planetData = {
      'type': 'planetData',
      'data': {
        // Basic properties
        'name': widget.planet.name,
        'biome': widget.biome.type,

        // Physical characteristics
        'temperature': widget.planet.equilibriumTemperature ?? 285,
        'mass': widget.planet.mass ?? 1.0, // Earth masses
        'radius': widget.planet.radius ?? 1.0, // Earth radii
        'gravity':
            (widget.planet.mass ?? 1.0) /
            ((widget.planet.radius ?? 1.0) * (widget.planet.radius ?? 1.0)),

        // Orbital properties (affect tidal locking, seasons)
        'orbitalPeriod': widget.planet.orbitalPeriod ?? 365,
        'semiMajorAxis': widget.planet.semiMajorAxis ?? 1.0, // AU
        'eccentricity': widget.planet.eccentricity ?? 0.0,

        // Stellar properties (affect lighting and atmosphere)
        'stellarType': widget.planet.stellarSpectralType ?? 'G2V',
        'stellarTemperature': widget.planet.stellarTemperature ?? 5778,
        'stellarMass': widget.planet.stellarMass ?? 1.0,

        // Discovery info (rough age indicator)
        'discoveryYear': widget.planet.discoveryYear ?? 2020,

        // Derived properties
        'atmosphere': widget.biome.atmosphereComposition,
        'lifeforms': _getLifeForms(),
        'habitability': widget.planet.habitabilityScore ?? 0,

        // Calculated features for rendering
        'isTidallyLocked': _isTidallyLocked(),
        'hasStrongMagneticField':
            (widget.planet.mass ?? 1.0) > 0.5 &&
            (widget.planet.mass ?? 1.0) < 3.0,
        'tectonicActivity': _calculateTectonicActivity(),
        'ageIndicator': _getRelativeAge(),
      },
    };

    // Send message to ALL iframes on the page
    final message = jsonEncode(planetData);

    // Try to find our specific iframe and send message
    final iframes = html.document.getElementsByTagName('iframe');
    for (var iframe in iframes) {
      if (iframe is html.IFrameElement &&
          iframe.src?.contains('planet_3d_viewer.html') == true) {
        iframe.contentWindow?.postMessage(message, '*');
        print('[3D-VIEWER] Sent planet data to iframe: ${widget.planet.name}');
      }
    }

    // Also send to window (fallback)
    html.window.postMessage(message, '*');
  }

  Future<void> _applyAIEnhancements() async {
    if (!mounted) return;

    setState(() {
      _isEnhancing = true;
      _enhancementStatus = 'Generating AI enhancements...';
    });

    try {
      print('[AI-ENHANCE] Requesting enhancement for: ${widget.planet.name}');

      // Get enhancement code (cache-first)
      final result = await _enhancementService.getEnhancementCode(
        widget.planet,
        widget.biome.type,
      );

      if (!mounted) return;

      // Update status based on cache hit
      setState(() {
        _enhancementStatus = result.fromCache
            ? '✓ Using cached enhancements'
            : '✓ AI-generated enhancements applied';
      });

      print(
        '[AI-ENHANCE] Got enhancement code (${result.fromCache ? "CACHED" : "GENERATED"})',
      );

      // Send enhancement code to iframe
      _sendEnhancementCode(result.code, result.fromCache);

      // Clear status after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isEnhancing = false;
            _enhancementStatus = '';
          });
        }
      });
    } catch (e) {
      print('[AI-ENHANCE] ❌ Error: $e');

      if (mounted) {
        setState(() {
          _isEnhancing = false;
          _enhancementStatus = '⚠ Enhancement failed';
        });
      }

      // Clear error message after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _enhancementStatus = '';
          });
        }
      });
    }
  }

  void _sendEnhancementCode(String code, bool fromCache) {
    final enhancementData = {
      'type': 'enhancementCode',
      'code': code,
      'fromCache': fromCache,
      'planetName': widget.planet.name,
    };

    final message = jsonEncode(enhancementData);

    // Send to all planet viewer iframes
    final iframes = html.document.getElementsByTagName('iframe');
    for (var iframe in iframes) {
      if (iframe is html.IFrameElement &&
          iframe.src?.contains('planet_3d_viewer.html') == true) {
        iframe.contentWindow?.postMessage(message, '*');
        print(
          '[AI-ENHANCE] Sent enhancement code to iframe (${fromCache ? "CACHED" : "GENERATED"})',
        );
      }
    }

    // Fallback
    html.window.postMessage(message, '*');
  }

  String _getLifeForms() {
    if (!widget.biome.supportsLife) {
      return 'None';
    }

    final temp = widget.planet.equilibriumTemperature ?? 285;
    final habitability = widget.planet.habitabilityScore ?? 0;

    if (habitability > 70) {
      return 'Complex Life, Animals, Plants';
    } else if (habitability > 40) {
      if (temp < 273) {
        return 'Extremophiles, Simple Organisms';
      } else if (temp > 320) {
        return 'Thermophiles, Heat-Resistant Microbes';
      } else {
        return 'Microorganisms, Simple Plants';
      }
    } else {
      return 'Possible Microbial Life';
    }
  }

  /// Determine if planet is tidally locked to its star
  /// Occurs for planets very close to their star (short orbital period)
  bool _isTidallyLocked() {
    final orbitalPeriod = widget.planet.orbitalPeriod;
    final semiMajorAxis = widget.planet.semiMajorAxis;

    if (orbitalPeriod == null || semiMajorAxis == null) return false;

    // Planets with orbital period < 10 days are likely tidally locked
    // Or very close orbits (< 0.1 AU)
    return orbitalPeriod < 10 || semiMajorAxis < 0.1;
  }

  /// Calculate tectonic activity based on planet properties
  /// Larger rocky planets (0.5-3 Earth masses) have more active tectonics
  double _calculateTectonicActivity() {
    final mass = widget.planet.mass ?? 1.0;
    final temp = widget.planet.equilibriumTemperature ?? 285;

    // Gas giants and very small planets have no plate tectonics
    if (mass > 5.0 || mass < 0.3) return 0.0;

    // Optimal range for plate tectonics: 0.5-3 Earth masses
    // Temperature affects mantle convection (too hot or cold reduces activity)
    double activity = 0.5;

    if (mass >= 0.5 && mass <= 3.0) {
      activity = 1.0 - ((1.5 - mass).abs() / 1.5) * 0.5;
    }

    // Temperature modifier
    if (temp > 200 && temp < 400) {
      activity *= 1.2; // Ideal temperature range
    } else if (temp > 500 || temp < 150) {
      activity *= 0.5; // Too extreme
    }

    return math.min(activity, 1.0);
  }

  /// Get relative age indicator (0 = very young, 1 = ancient)
  /// Rough estimate based on discovery method and stellar type
  double _getRelativeAge() {
    // Hot Jupiters and close-in planets are typically in young systems
    final orbitalPeriod = widget.planet.orbitalPeriod ?? 365;
    if (orbitalPeriod < 5) return 0.3; // Young, migrated planet

    // Planets around old red dwarfs are typically ancient
    final stellarType = widget.planet.stellarSpectralType ?? 'G';
    if (stellarType.startsWith('M')) return 0.8; // Old red dwarf
    if (stellarType.startsWith('K')) return 0.6; // Mid-age
    if (stellarType.startsWith('F') || stellarType.startsWith('A')) {
      return 0.2; // Young, hot star
    }

    // Sun-like stars (G-type) are middle-aged
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The Three.js iframe viewer (lowest layer)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false, // Allow iframe interactions
              child: HtmlElementView(viewType: viewId),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF667eea),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Generating 3D Planet World...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Applying real planetary data to terrain generation',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // AI Enhancement status indicator
          if (_enhancementStatus.isNotEmpty)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isEnhancing
                        ? [
                            const Color(0xFF667eea).withOpacity(0.9),
                            const Color(0xFF764ba2).withOpacity(0.9),
                          ]
                        : _enhancementStatus.contains('✓')
                        ? [
                            Colors.green.withOpacity(0.9),
                            Colors.teal.withOpacity(0.9),
                          ]
                        : [
                            Colors.orange.withOpacity(0.9),
                            Colors.red.withOpacity(0.9),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isEnhancing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        _enhancementStatus.contains('✓')
                            ? Icons.check_circle
                            : Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _enhancementStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay (top-right) - Interactive layer
          Positioned(
            top: _enhancementStatus.isNotEmpty ? 70 : 20,
            right: 20,
            child: IgnorePointer(
              ignoring: false, // Make this interactive
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.15),
                      const Color(0xFF764ba2).withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.keyboard,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Controls',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildControlItem('🖱️ Drag', 'Rotate camera'),
                    _buildControlItem('🔍 Scroll', 'Zoom in/out'),
                    _buildControlItem('[Cam] Free Cam', 'Enable WASD movement'),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0),
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildControlItem('W/A/S/D', 'Move (Free Cam)'),
                    _buildControlItem('Q/E', 'Up/Down (Free Cam)'),
                  ],
                ),
              ),
            ),
          ),

          // Back button (top-left) - Highest z-index
          Positioned(
            top: 20,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('[3D-VIEWER] Back button tapped - popping navigator');
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withOpacity(0.3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF667eea).withOpacity(0.9),
                        const Color(0xFF764ba2).withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlItem(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
