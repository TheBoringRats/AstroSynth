// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../models/biome.dart';
import '../models/planet.dart';

/// Interactive 3D planet visualization widget using Three.js
///
/// Features:
/// - Full 3D WebGL rendering with realistic surfaces
/// - Interactive zoom, rotate, and pan controls
/// - Procedural textures based on planet data
/// - Atmosphere and cloud layers
/// - Data-driven surface details (temperature, composition, biome)
class Planet3DViewer extends StatefulWidget {
  final Planet planet;
  final Biome biome;
  final bool showOrbit;
  final bool showComparison;
  final bool autoRotate;

  const Planet3DViewer({
    super.key,
    required this.planet,
    required this.biome,
    this.showOrbit = false,
    this.showComparison = false,
    this.autoRotate = true,
  });

  @override
  State<Planet3DViewer> createState() => _Planet3DViewerState();
}

class _Planet3DViewerState extends State<Planet3DViewer> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'planet-3d-viewer-${widget.planet.name.replaceAll(' ', '-')}';
    _registerView();
  }

  void _registerView() {
    // Register the platform view for embedding the 3D canvas
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = html.DivElement()
        ..id = _viewId
        ..style.width = '100%'
        ..style.height = '100%';

      // Wait for the element to be added to the DOM
      Future.delayed(const Duration(milliseconds: 200), () {
        _create3DViewer();
      });

      return container;
    });
  }

  void _create3DViewer() {
    // Get planet data
    final planetData = js.JsObject.jsify({
      'name': widget.planet.name,
      'temperature': widget.planet.equilibriumTemperature,
      'mass': widget.planet.mass,
      'radius': widget.planet.radius,
      'density': 1.0,
      'biome': widget.biome.type,
      'atmosphere': 'Unknown',
      'gravity': 1.0,
    });

    // Call JavaScript function to create the 3D viewer
    try {
      final createFunction = js.context['create3DPlanetViewer'];
      if (createFunction != null) {
        createFunction.apply([_viewId, planetData]);
      }
    } catch (e) {
      debugPrint('Error creating 3D viewer: $e');
    }
  }

  @override
  void dispose() {
    // Clean up the 3D viewer
    try {
      final destroyFunction = js.context['destroy3DPlanetViewer'];
      if (destroyFunction != null) {
        destroyFunction.apply([_viewId]);
      }
    } catch (e) {
      debugPrint('Error destroying 3D viewer: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: HtmlElementView(viewType: _viewId)),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Instructions
          const Icon(Icons.info_outline, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          const Text(
            'Drag to rotate • Scroll to zoom',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 16),
          // Size comparison
          if (widget.planet.radius != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.public, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.planet.radius!.toStringAsFixed(2)}x Earth',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
