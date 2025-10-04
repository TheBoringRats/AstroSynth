import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/biome.dart';
import '../models/planet.dart';

/// Card widget displaying planet information in grid view
class PlanetCard extends StatefulWidget {
  final Planet planet;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const PlanetCard({
    super.key,
    required this.planet,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<PlanetCard> createState() => _PlanetCardState();
}

class _PlanetCardState extends State<PlanetCard> {
  bool _isHovered = false;
  String? _canvasViewType;

  @override
  void initState() {
    super.initState();
    _registerPlanetCanvas();
  }

  void _registerPlanetCanvas() {
    final viewType = 'planet-canvas-${widget.planet.displayName.hashCode}';
    _canvasViewType = viewType;

    // Register the canvas element factory for this planet
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final canvas = html.CanvasElement()
        ..width = 180
        ..height = 180
        ..style.width = '90px'
        ..style.height = '90px';

      // Pass planet data to JavaScript
      final biome = Biome.classify(
        temperature: widget.planet.equilibriumTemperature,
        radius: widget.planet.radius,
        mass: widget.planet.mass,
      );

      final planetData = {
        'name': widget.planet.displayName,
        'temperature': widget.planet.equilibriumTemperature ?? 288.0,
        'mass': widget.planet.mass ?? 1.0,
        'radius': widget.planet.radius ?? 1.0,
        'density':
            (widget.planet.mass ?? 1.0) /
            math.pow(widget.planet.radius ?? 1.0, 2),
        'biome': biome.type,
      };

      // Set unique canvas ID
      final canvasId = 'planet-canvas-${widget.planet.displayName.hashCode}';
      canvas.id = canvasId;

      // Create planet renderer using JavaScript after a brief delay
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          // Call JavaScript function to create animated planet
          final scriptElement = html.ScriptElement()
            ..text =
                '''
                if (window.createPlanetRenderer) {
                  const canvas = document.getElementById('$canvasId');
                  if (canvas) {
                    window.createPlanetRenderer('$canvasId', ${jsonEncode(planetData)});
                  }
                }
              ''';
          html.document.body?.append(scriptElement);
          scriptElement.remove();
        } catch (e) {
          print(
            'Error creating planet renderer for ${widget.planet.displayName}: $e',
          );
        }
      });

      return canvas;
    });
  }

  @override
  Widget build(BuildContext context) {
    final biome = Biome.classify(
      temperature: widget.planet.equilibriumTemperature,
      radius: widget.planet.radius,
      mass: widget.planet.mass,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: Card(
          elevation: _isHovered ? 12 : 4,
          shadowColor: _getBiomeColor(biome).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
            side: BorderSide(
              color: _isHovered
                  ? _getBiomeColor(biome).withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.cardBackground,
                    AppTheme.cardBackground.withValues(alpha: 0.9),
                    _getBiomeColor(biome).withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, biome),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPlanetInfo(context),
                          _buildStatsRow(context),
                          if (widget.planet.habitabilityScore != null)
                            _buildHabitabilityBadge(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Biome biome) {
    return Container(
      height: 140, // Increased height for planet sphere
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.defaultBorderRadius),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _getBiomeColor(biome).withValues(alpha: 0.8),
            _getBiomeColor(biome).withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated planet sphere (stars are included in JavaScript animation)
          Center(child: _buildPlanetSphere(biome)),
          // Biome badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBiomeColor(biome).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getBiomeIcon(biome),
                    size: 12,
                    color: _getBiomeColor(biome),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    biome.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Favorite button
          if (widget.onFavoriteToggle != null)
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: widget.onFavoriteToggle,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.planet.isFavorite
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.transparent,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.planet.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.planet.isFavorite ? Colors.red : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanetSphere(Biome biome) {
    final planetColor = _getBiomeColor(biome);

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Outer glow
          BoxShadow(
            color: planetColor.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          // Inner shadow for 3D effect
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: _canvasViewType != null
            ? HtmlElementView(viewType: _canvasViewType!)
            : Container(
                color: planetColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPlanetInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.planet.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (widget.planet.hostStarName != null)
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: AppTheme.warningColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.planet.hostStarName!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.planet.discoveryYear != null)
          _buildStatItem(
            context,
            Icons.calendar_today,
            widget.planet.discoveryYear.toString(),
          ),
        if (widget.planet.distanceFromEarth != null &&
            widget.planet.distanceInLightYears != null)
          _buildStatItem(
            context,
            Icons.location_on,
            '${widget.planet.distanceInLightYears!.toStringAsFixed(1)} ly',
          ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildHabitabilityBadge(BuildContext context) {
    final score = widget.planet.habitabilityScore!;
    final category = widget.planet.habitabilityCategory;
    final color = AppTheme.getHabitabilityColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$category ${score.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBiomeColor(Biome biome) {
    final temp = widget.planet.equilibriumTemperature ?? 288.0;
    final mass = widget.planet.mass ?? 1.0;
    final radius = widget.planet.radius ?? 1.0;

    // Generate unique color based on planet properties
    final uniqueSeed = widget.planet.displayName.hashCode % 100;

    // Base color from biome type
    Color baseColor;
    switch (biome.type) {
      case 'Ocean World':
        baseColor = const Color(0xFF0984E3);
        break;
      case 'Desert World':
        baseColor = const Color(0xFFFDCB6E);
        break;
      case 'Ice World':
        baseColor = const Color(0xFF74B9FF);
        break;
      case 'Volcanic World':
        baseColor = const Color(0xFFD63031);
        break;
      case 'Tropical Paradise':
        baseColor = AppTheme.secondaryColor;
        break;
      case 'Temperate World':
        baseColor = const Color(0xFF55EFC4);
        break;
      case 'Tundra World':
        baseColor = const Color(0xFFB2BEC3);
        break;
      case 'Barren Rock':
        baseColor = const Color(0xFF636E72);
        break;
      case 'Gas Giant':
        baseColor = const Color(0xFFA29BFE);
        break;
      case 'Rocky Planet':
        baseColor = const Color(0xFF6C5CE7);
        break;
      default:
        baseColor = AppTheme.primaryColor;
    }

    // Modify color based on temperature (makes each planet unique)
    double hueShift = 0.0;
    double saturationFactor = 1.0;
    double brightnessFactor = 1.0;

    if (temp > 1500) {
      // Ultra hot: shift to white-orange
      hueShift = -20;
      saturationFactor = 0.7;
      brightnessFactor = 1.3;
    } else if (temp > 800) {
      // Very hot: shift to orange-red
      hueShift = -10 + (uniqueSeed % 15);
      saturationFactor = 0.9;
      brightnessFactor = 1.1;
    } else if (temp > 400) {
      // Hot: slight red shift
      hueShift = -5 + (uniqueSeed % 10);
      saturationFactor = 1.0;
      brightnessFactor = 1.05;
    } else if (temp < 100) {
      // Very cold: shift to blue-white
      hueShift = 10 + (uniqueSeed % 15);
      saturationFactor = 0.6;
      brightnessFactor = 0.9;
    } else if (temp < 200) {
      // Cold: slight blue shift
      hueShift = 5 + (uniqueSeed % 10);
      saturationFactor = 0.8;
      brightnessFactor = 0.95;
    } else {
      // Temperate: unique variation
      hueShift = (uniqueSeed % 20) - 10.0;
      saturationFactor = 0.9 + (uniqueSeed % 20) / 200.0;
      brightnessFactor = 0.95 + (uniqueSeed % 10) / 100.0;
    }

    // Modify based on mass (larger = darker, smaller = lighter)
    if (mass > 10) {
      // Super massive gas giant
      brightnessFactor *= 0.85;
      saturationFactor *= 1.1;
    } else if (mass > 5) {
      // Large gas giant
      brightnessFactor *= 0.9;
    } else if (mass < 0.5) {
      // Small planet
      brightnessFactor *= 1.1;
      saturationFactor *= 0.9;
    }

    // Modify based on density (mass/radius ratio)
    final density = radius > 0 ? mass / (radius * radius) : 1.0;
    if (density > 2) {
      // High density (rocky/metallic) - darker, more saturated
      saturationFactor *= 1.15;
      brightnessFactor *= 0.95;
    } else if (density < 0.5) {
      // Low density (fluffy gas giant) - lighter, less saturated
      saturationFactor *= 0.85;
      brightnessFactor *= 1.05;
    }

    // Apply color modifications
    final hsl = HSLColor.fromColor(baseColor);
    final modifiedColor = hsl
        .withHue((hsl.hue + hueShift) % 360)
        .withSaturation((hsl.saturation * saturationFactor).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * brightnessFactor).clamp(0.0, 1.0))
        .toColor();

    return modifiedColor;
  }

  IconData _getBiomeIcon(Biome biome) {
    switch (biome.type) {
      case 'Ocean World':
        return Icons.water;
      case 'Desert World':
        return Icons.wb_sunny;
      case 'Ice World':
        return Icons.ac_unit;
      case 'Volcanic World':
        return Icons.local_fire_department;
      case 'Tropical Paradise':
        return Icons.forest;
      case 'Temperate World':
        return Icons.eco;
      case 'Tundra World':
        return Icons.cloud;
      case 'Barren Rock':
        return Icons.landscape;
      case 'Gas Giant':
        return Icons.public;
      case 'Rocky Planet':
        return Icons.terrain;
      default:
        return Icons.language;
    }
  }
}
