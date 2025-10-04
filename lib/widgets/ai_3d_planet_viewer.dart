import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../models/biome.dart';
import '../models/planet.dart';
import '../services/ai_planet_generator_service.dart';

/// AI-Powered 3D Planet Viewer
///
/// Architecture:
/// 1. User selects planet
/// 2. Flutter sends NASA data to OpenRouter API
/// 3. AI generates custom Three.js code
/// 4. Code is dynamically executed in iframe
/// 5. Real-time 3D visualization rendered
class AI3DPlanetViewer extends StatefulWidget {
  final Planet planet;

  const AI3DPlanetViewer({super.key, required this.planet});

  @override
  State<AI3DPlanetViewer> createState() => _AI3DPlanetViewerState();
}

class _AI3DPlanetViewerState extends State<AI3DPlanetViewer> {
  final String viewId =
      'ai-planet-viewer-${DateTime.now().millisecondsSinceEpoch}';
  final AIPlanetGeneratorService _aiService = AIPlanetGeneratorService();

  bool _isGenerating = false;
  bool _hasGenerated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _registerIframe();

    // Start AI generation automatically
    Future.delayed(const Duration(milliseconds: 500), () {
      _generateAIVisualization();
    });
  }

  void _registerIframe() {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'ai_planet_viewer.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'auto';

      return iframe;
    });
  }

  Future<void> _generateAIVisualization() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    print('[AI-3D] 🚀 Starting AI generation for: ${widget.planet.name}');

    // Get biome classification
    final biome = Biome.classify(
      temperature: widget.planet.equilibriumTemperature,
      radius: widget.planet.radius,
      mass: widget.planet.mass,
    );

    // Call AI service
    final code = await _aiService.generatePlanetVisualization(
      widget.planet,
      biome.type,
    );

    if (code != null) {
      setState(() {
        _hasGenerated = true;
        _isGenerating = false;
      });

      // Send to iframe
      _sendAICode(code);
    } else {
      setState(() {
        _error = 'AI generation failed. Please try again.';
        _isGenerating = false;
      });
    }
  }

  void _sendAICode(String code) {
    final message = jsonEncode({
      'type': 'aiGeneratedCode',
      'code': code,
      'planetData': {
        'name': widget.planet.name,
        'mass': widget.planet.mass,
        'radius': widget.planet.radius,
        'temperature': widget.planet.equilibriumTemperature,
      },
    });

    // Find iframe and send message
    final iframes = html.document.getElementsByTagName('iframe');
    for (var iframe in iframes) {
      if (iframe is html.IFrameElement &&
          iframe.src?.contains('ai_planet_viewer.html') == true) {
        iframe.contentWindow?.postMessage(message, '*');
        print('[AI-3D] ✅ Sent AI code to iframe');
      }
    }

    html.window.postMessage(message, '*');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3D Viewer iframe
          Positioned.fill(child: HtmlElementView(viewType: viewId)),

          // Back button
          Positioned(
            top: 40,
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // AI Status banner
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _isGenerating || _error != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (_error != null ? Colors.red : Colors.blue).withOpacity(
                        0.9,
                      ),
                      (_error != null ? Colors.red : Colors.blue).withOpacity(
                        0.7,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_error != null ? Colors.red : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    else if (_error != null)
                      const Icon(Icons.error_outline, color: Colors.white)
                    else
                      const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error ??
                            (_isGenerating
                                ? '🤖 AI generating visualization for ${widget.planet.name}...'
                                : 'AI generation complete!'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Retry button (if error)
          if (_error != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _generateAIVisualization,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry AI Generation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

          // Info badge
          if (_hasGenerated && _error == null)
            Positioned(
              bottom: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.8),
                      Colors.blue.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'AI-Generated',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
