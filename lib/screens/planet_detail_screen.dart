import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/atmospheric_profile.dart';
import '../models/biome.dart';
import '../models/enhanced_habitability_result.dart';
import '../models/habitability_result.dart';
import '../models/planet.dart';
import '../services/atmospheric_modeler.dart';
import '../services/enhanced_habitability_calculator.dart';
import '../services/habitability_calculator.dart';
import '../services/nasa_style_page_generator.dart';
import '../widgets/atmosphere_chart.dart';
import '../widgets/habitability_spider_chart.dart';
import '../widgets/planet_3d_world_viewer.dart';
import 'evolution_simulator_screen.dart';
import 'planet_comparison_screen.dart';
import 'terraform_simulator_screen.dart';
import 'time_evolution_screen.dart';

/// Detailed view of a single planet with comprehensive information
class PlanetDetailScreen extends StatefulWidget {
  final Planet planet;

  const PlanetDetailScreen({super.key, required this.planet});

  @override
  State<PlanetDetailScreen> createState() => _PlanetDetailScreenState();
}

class _PlanetDetailScreenState extends State<PlanetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HabitabilityResult? _habitabilityResult;
  late EnhancedHabitabilityResult? _enhancedResult;
  late AtmosphericProfile _atmosphere;
  late Biome _biome;
  final HabitabilityCalculator _calculator = HabitabilityCalculator();
  final EnhancedHabitabilityCalculator _enhancedCalculator =
      EnhancedHabitabilityCalculator();
  final AtmosphericModeler _atmosphericModeler = AtmosphericModeler();
  final NASAStylePageGenerator _nasaPageGenerator = NASAStylePageGenerator();
  bool _generatingNASAPage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Calculate habitability if sufficient data
    if (widget.planet.hasSufficientData) {
      _habitabilityResult = _calculator.calculateHabitability(widget.planet);
      _enhancedResult = _enhancedCalculator.calculateHabitability(
        widget.planet,
      );
    } else {
      _habitabilityResult = null;
      _enhancedResult = null;
    }

    // Classify biome
    _biome = Biome.classify(
      temperature: widget.planet.equilibriumTemperature,
      radius: widget.planet.radius,
      mass: widget.planet.mass,
    );

    // Generate atmospheric profile
    _atmosphere = _atmosphericModeler.generateAtmosphere(widget.planet, _biome);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spaceBackgroundGradient),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                children: [_buildHeader(), _buildTabBar(), _buildTabContent()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.planet.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black87,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_getBiomeColor(_biome), AppTheme.darkBackground],
            ),
          ),
          child: Center(
            child: Icon(
              _getBiomeIcon(_biome),
              size: 120,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareplanet(),
        ),
        IconButton(
          icon: Icon(
            widget.planet.isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          onPressed: () {
            // TODO: Toggle favorite
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Host Star Info
          if (widget.planet.hostStarName != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: AppTheme.warningColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Host Star: ${widget.planet.hostStarName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat(
                context,
                Icons.calendar_today,
                'Discovered',
                widget.planet.discoveryYear?.toString() ?? 'Unknown',
              ),
              _buildQuickStat(
                context,
                Icons.location_on,
                'Distance',
                widget.planet.distanceFromEarth != null
                    ? '${widget.planet.distanceInLightYears!.toStringAsFixed(1)} ly'
                    : 'Unknown',
              ),
              _buildQuickStat(
                context,
                Icons.science,
                'Method',
                _getShortMethod(widget.planet.discoveryMethod),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Habitability Badge
          if (_habitabilityResult != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.getHabitabilityColor(
                  _habitabilityResult!.overallScore,
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.getHabitabilityColor(
                    _habitabilityResult!.overallScore,
                  ),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco,
                    color: AppTheme.getHabitabilityColor(
                      _habitabilityResult!.overallScore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Habitability: ${_habitabilityResult!.overallScore.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.getHabitabilityColor(
                        _habitabilityResult!.overallScore,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.planet.habitabilityCategory})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TerraformSimulatorScreen(planet: widget.planet),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_suggest, size: 20),
                  label: const Text(
                    'Terraform',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TimeEvolutionScreen(planet: widget.planet),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timeline, size: 20),
                  label: const Text(
                    'Time Evolution',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // NASA Eyes-inspired Comparison Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PlanetComparisonScreen(initialPlanets: [widget.planet]),
                  ),
                );
              },
              icon: const Icon(Icons.compare_arrows, size: 20),
              label: const Text(
                'Compare with Other Planets',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17055),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Habitability'),
          Tab(text: '3D View'),
          Tab(text: 'Data'),
          Tab(text: 'NASA View'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHabitabilityTab(),
          _build3DViewTab(),
          _buildDataTab(),
          _buildNASAViewTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Biome Classification'),
          _buildBiomeCard(),
          _buildEvolutionSimulatorButton(),
          const SizedBox(height: 24),

          _buildSectionTitle('Atmospheric Composition'),
          _buildAtmosphericComposition(),
          const SizedBox(height: 24),

          _buildSectionTitle('Physical Characteristics'),
          _buildPhysicalCharacteristics(),
          const SizedBox(height: 24),

          _buildSectionTitle('Orbital Properties'),
          _buildOrbitalProperties(),
          const SizedBox(height: 24),

          _buildSectionTitle('Host Star'),
          _buildHostStarInfo(),
        ],
      ),
    );
  }

  Widget _buildHabitabilityTab() {
    if (_enhancedResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Insufficient data for habitability analysis',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Score Badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _enhancedResult!.color,
                    _enhancedResult!.color.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _enhancedResult!.color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${_enhancedResult!.overallScore.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _enhancedResult!.category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionTitle('8-Factor Analysis'),
          Card(
            color: AppTheme.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // Spider Chart
                  HabitabilitySpiderChart(result: _enhancedResult!, size: 320),
                  const SizedBox(height: 24),
                  // Factor List with Bars
                  HabitabilityFactorList(result: _enhancedResult!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Detailed Analysis'),
          _buildEnhancedHabitabilityAnalysis(),
          const SizedBox(height: 24),

          _buildSectionTitle('Strengths'),
          _buildEnhancedStrengthsList(),
          const SizedBox(height: 16),

          _buildSectionTitle('Weaknesses'),
          _buildEnhancedWeaknessesList(),
          const SizedBox(height: 24),

          _buildSectionTitle('Recommendations'),
          _buildEnhancedRecommendationsList(),
        ],
      ),
    );
  }

  Widget _build3DViewTab() {
    return Container(
      color: AppTheme.darkBackground,
      child: Column(
        children: [
          // NASA Eyes on Exoplanets iframe
          Expanded(child: _buildNASAEyesViewer()),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // AI-Powered 3D Viewer Button
                ElevatedButton.icon(
                  onPressed: () => _openAI3DViewer(),
                  icon: const Icon(Icons.auto_awesome, size: 24),
                  label: const Text(
                    '🤖 AI-Generated 3D Planet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D4EDD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF9D4EDD).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                // Procedural 3D Viewer Button
                ElevatedButton.icon(
                  onPressed: () => _open3DWorldViewer(),
                  icon: const Icon(Icons.explore, size: 24),
                  label: const Text(
                    'Procedural 3D Planet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🌐 NASA Eyes • 🤖 AI Custom • ⚙️ Procedural',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Convert planet name to NASA Eyes format
  /// Example: "TOI-2031 A b" -> "TOI-2031_A_b"
  /// Example: "Kepler-442 b" -> "Kepler-442_b"
  /// Example: "WASP-102 b" -> "WASP-102_b"
  String _convertPlanetNameToNASAFormat(String name) {
    // Replace all spaces with underscores
    return name.replaceAll(' ', '_');
  }

  /// Build NASA Eyes on Exoplanets iframe viewer
  Widget _buildNASAEyesViewer() {
    final nasaFormatName = _convertPlanetNameToNASAFormat(
      widget.planet.displayName,
    );
    final nasaEyesUrl =
        'https://eyes.nasa.gov/apps/exo/#/planet/$nasaFormatName';

    // Register the iframe view
    final viewId = 'nasa-eyes-viewer-${widget.planet.displayName.hashCode}';

    try {
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int vId) {
        final iframe = html.IFrameElement()
          ..src = nasaEyesUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..setAttribute('loading', 'lazy')
          ..setAttribute('allow', 'fullscreen');

        return iframe;
      });
    } catch (e) {
      // View already registered
      print('NASA Eyes viewer already registered: $viewId');
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000510), Color(0xFF0a0e27)],
        ),
      ),
      child: Stack(
        children: [
          // NASA Eyes iframe
          HtmlElementView(viewType: viewId),

          // NASA Badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFC3D21).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFC3D21).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://science.nasa.gov/wp-content/themes/nasa/assets/images/nasa-logo.svg',
                    height: 16,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.public,
                        size: 16,
                        color: Colors.white,
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'NASA Eyes',
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

          // Controls hint
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Powered by NASA Eyes on Exoplanets',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanced3DPlanet() {
    // Create unique ID for this large 3D view
    final viewId =
        'planet-3d-viewer-large-${widget.planet.displayName.hashCode}';

    // Register the Three.js 3D viewer
    _register3DPlanetViewer(viewId);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000510), Color(0xFF0a0e27)],
        ),
      ),
      child: Stack(
        children: [
          // Three.js 3D viewer
          HtmlElementView(viewType: viewId),

          // Controls overlay
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Drag to rotate • Scroll to zoom',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _register3DPlanetViewer(String viewId) {
    // Import required for web
    // ignore: undefined_prefixed_name
    try {
      ui_web.platformViewRegistry.registerViewFactory(viewId, (int vId) {
        // Create a container div for the Three.js renderer
        final container = html.DivElement()
          ..id = viewId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.position = 'relative';

        // Pass comprehensive planet data to JavaScript
        final planetData = {
          'name': widget.planet.displayName,
          'temperature': widget.planet.equilibriumTemperature ?? 288.0,
          'mass': widget.planet.mass ?? 1.0,
          'radius': widget.planet.radius ?? 1.0,
          'density':
              (widget.planet.mass ?? 1.0) /
              math.pow(widget.planet.radius ?? 1.0, 2),
          'biome': _biome.type,
          'orbitalPeriod': widget.planet.orbitalPeriod,
          'eccentricity': widget.planet.eccentricity,
          'atmosphere': _atmosphere.dominantGas,
        };

        // Create Three.js 3D viewer with delay
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            final scriptElement = html.ScriptElement()
              ..text =
                  '''
                  if (window.create3DPlanetViewer && typeof THREE !== 'undefined') {
                    console.log('[3D-VIEWER] Creating Three.js 3D viewer for: ${widget.planet.displayName}');
                    window.create3DPlanetViewer('$viewId', ${jsonEncode(planetData)});
                  } else {
                    console.error('Three.js not loaded or create3DPlanetViewer not found');
                  }
                ''';
            html.document.body?.append(scriptElement);
            scriptElement.remove();
          } catch (e) {
            print('Error creating 3D planet viewer: $e');
          }
        });

        return container;
      });
    } catch (e) {
      // View already registered, that's okay
      print('3D viewer already registered: $viewId');
    }
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildSectionTitle('All Parameters'), _buildDataTable()],
      ),
    );
  }

  Widget _buildNASAViewTab() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.secondaryColor.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.public,
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'NASA-Style Planet Page',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'View ${widget.planet.displayName} in a beautiful,\ninteractive NASA-style page with embedded 3D viewer',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features List
          Card(
            color: AppTheme.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    Icons.image,
                    'Professional Design',
                    'NASA-inspired layout and styling',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.threed_rotation,
                    'Interactive 3D Viewer',
                    'Embedded NASA Eyes on Exoplanets',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.science,
                    'Discovery Details',
                    'Method, facility, and year',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.data_exploration,
                    'Complete Statistics',
                    'All physical and orbital properties',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Open Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generatingNASAPage ? null : _openNASAStylePage,
              icon: _generatingNASAPage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new, size: 24),
              label: Text(
                _generatingNASAPage
                    ? 'Generating Page...'
                    : 'Open NASA-Style View',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B3D91), // NASA blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info Text
          Text(
            'Page will open in a new browser tab',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openNASAStylePage() async {
    setState(() => _generatingNASAPage = true);

    try {
      print('[NASA-VIEW] Generating page for: ${widget.planet.name}');

      // Generate the HTML page
      final htmlContent = await _nasaPageGenerator.generatePlanetPage(
        widget.planet,
        fetchNASAData: true, // Try to enhance with NASA API
      );

      // Create a blob and open in new window
      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Open in new tab
      html.window.open(url, '_blank');

      print('[NASA-VIEW] ✅ Page opened successfully');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NASA-style page opened in new tab',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Clean up
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('[NASA-VIEW] ❌ Error: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to generate page: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingNASAPage = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBiomeCard() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getBiomeColor(_biome).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getBiomeIcon(_biome),
                size: 64,
                color: _getBiomeColor(_biome),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _biome.type,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getBiomeColor(_biome),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _biome.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _biome.characteristics
                  .map(
                    (char) => Chip(
                      label: Text(char),
                      backgroundColor: _getBiomeColor(
                        _biome,
                      ).withValues(alpha: 0.3),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionSimulatorButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to Evolution Simulator
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvolutionSimulatorScreen(
                planet: widget.planet,
                biome: _biome,
              ),
            ),
          );
        },
        icon: const Icon(Icons.science, size: 24),
        label: const Text(
          'Simulate Evolution',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAtmosphericComposition() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breathability indicator
            BreathabilityIndicator(atmosphere: _atmosphere),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: AtmospherePieChart(atmosphere: _atmosphere, size: 200),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 3,
                  child: AtmosphereLegend(atmosphere: _atmosphere),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Atmospheric stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDataRow(
                    'Pressure',
                    '${_atmosphere.pressure.toStringAsFixed(2)} atm',
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow(
                    'Density',
                    '${_atmosphere.density.toStringAsFixed(2)} kg/m³',
                  ),
                  const SizedBox(height: 8),
                  _buildDataRow('Dominant Gas', _atmosphere.dominantGas),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Characteristics
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _atmosphere.characteristics
                  .map(
                    (char) => Chip(
                      label: Text(char),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalCharacteristics() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            _buildDataRow(
              'Radius',
              widget.planet.radius != null
                  ? '${widget.planet.radius!.toStringAsFixed(2)} Earth radii'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Mass',
              widget.planet.mass != null
                  ? '${widget.planet.mass!.toStringAsFixed(2)} Earth masses'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Temperature',
              widget.planet.equilibriumTemperature != null
                  ? '${widget.planet.equilibriumTemperature!.toStringAsFixed(0)} K'
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbitalProperties() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            _buildDataRow(
              'Orbital Period',
              widget.planet.orbitalPeriod != null
                  ? '${widget.planet.orbitalPeriod!.toStringAsFixed(2)} days'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Semi-Major Axis',
              widget.planet.semiMajorAxis != null
                  ? '${widget.planet.semiMajorAxis!.toStringAsFixed(3)} AU'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Eccentricity',
              widget.planet.eccentricity != null
                  ? widget.planet.eccentricity!.toStringAsFixed(3)
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostStarInfo() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            _buildDataRow('Name', widget.planet.hostStarName ?? 'Unknown'),
            _buildDataRow(
              'Spectral Type',
              widget.planet.stellarSpectralType ?? 'Unknown',
            ),
            _buildDataRow(
              'Temperature',
              widget.planet.stellarTemperature != null
                  ? '${widget.planet.stellarTemperature!.toStringAsFixed(0)} K'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Radius',
              widget.planet.stellarRadius != null
                  ? '${widget.planet.stellarRadius!.toStringAsFixed(2)} Solar radii'
                  : 'Unknown',
            ),
            _buildDataRow(
              'Mass',
              widget.planet.stellarMass != null
                  ? '${widget.planet.stellarMass!.toStringAsFixed(2)} Solar masses'
                  : 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitabilityChart() {
    if (_habitabilityResult == null) return const SizedBox();

    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const titles = [
                            'Temp',
                            'Size',
                            'Star',
                            'Orbit',
                            'Overall',
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textMuted.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _buildBarGroup(0, _habitabilityResult!.temperatureScore),
                    _buildBarGroup(1, _habitabilityResult!.sizeScore),
                    _buildBarGroup(2, _habitabilityResult!.starScore),
                    _buildBarGroup(3, _habitabilityResult!.orbitScore),
                    _buildBarGroup(4, _habitabilityResult!.overallScore),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: AppTheme.getHabitabilityColor(value),
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildHabitabilityAnalysis() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisItem(
              'Temperature',
              _habitabilityResult!.temperatureAnalysis,
              _habitabilityResult!.temperatureScore,
            ),
            const Divider(),
            _buildAnalysisItem(
              'Size',
              _habitabilityResult!.sizeAnalysis,
              _habitabilityResult!.sizeScore,
            ),
            const Divider(),
            _buildAnalysisItem(
              'Star Type',
              _habitabilityResult!.starAnalysis,
              _habitabilityResult!.starScore,
            ),
            const Divider(),
            _buildAnalysisItem(
              'Orbit',
              _habitabilityResult!.orbitAnalysis,
              _habitabilityResult!.orbitScore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String title, String analysis, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getHabitabilityColor(
                    score,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppTheme.getHabitabilityColor(score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            analysis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _habitabilityResult!.strengths
              .map(
                (strength) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.habitableHigh,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strength,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWeaknessesList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _habitabilityResult!.weaknesses
              .map(
                (weakness) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppTheme.habitableLow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          weakness,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _habitabilityResult!.recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ============================================================
  // ENHANCED HABITABILITY WIDGETS (8 Factors)
  // ============================================================

  Widget _buildEnhancedHabitabilityAnalysis() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _enhancedResult!.factorAnalyses.entries.map((entry) {
            final score = _enhancedResult!.factorScores[entry.key]!;
            return Column(
              children: [
                _buildAnalysisItem(entry.key, entry.value, score),
                if (entry.key != _enhancedResult!.factorAnalyses.keys.last)
                  const Divider(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedStrengthsList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _enhancedResult!.strengths
              .map(
                (strength) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.habitableHigh,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strength,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedWeaknessesList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _enhancedResult!.weaknesses
              .map(
                (weakness) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppTheme.habitableLow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          weakness,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedRecommendationsList() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: _enhancedResult!.recommendations
              .map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final data = <String, String>{
      'Planet Name': widget.planet.name,
      'Host Star': widget.planet.hostStarName ?? 'Unknown',
      'Distance': widget.planet.distanceFromEarth != null
          ? '${widget.planet.distanceFromEarth!.toStringAsFixed(2)} parsecs'
          : 'Unknown',
      'Discovery Year': widget.planet.discoveryYear?.toString() ?? 'Unknown',
      'Discovery Method': widget.planet.discoveryMethod ?? 'Unknown',
      'Orbital Period': widget.planet.orbitalPeriod != null
          ? '${widget.planet.orbitalPeriod!.toStringAsFixed(2)} days'
          : 'Unknown',
      'Planet Radius': widget.planet.radius != null
          ? '${widget.planet.radius!.toStringAsFixed(2)} Earth radii'
          : 'Unknown',
      'Planet Mass': widget.planet.mass != null
          ? '${widget.planet.mass!.toStringAsFixed(2)} Earth masses'
          : 'Unknown',
      'Equilibrium Temperature': widget.planet.equilibriumTemperature != null
          ? '${widget.planet.equilibriumTemperature!.toStringAsFixed(0)} K'
          : 'Unknown',
      'Semi-Major Axis': widget.planet.semiMajorAxis != null
          ? '${widget.planet.semiMajorAxis!.toStringAsFixed(3)} AU'
          : 'Unknown',
      'Eccentricity': widget.planet.eccentricity != null
          ? widget.planet.eccentricity!.toStringAsFixed(3)
          : 'Unknown',
      'Stellar Spectral Type': widget.planet.stellarSpectralType ?? 'Unknown',
      'Stellar Temperature': widget.planet.stellarTemperature != null
          ? '${widget.planet.stellarTemperature!.toStringAsFixed(0)} K'
          : 'Unknown',
      'Stellar Radius': widget.planet.stellarRadius != null
          ? '${widget.planet.stellarRadius!.toStringAsFixed(2)} Solar radii'
          : 'Unknown',
      'Stellar Mass': widget.planet.stellarMass != null
          ? '${widget.planet.stellarMass!.toStringAsFixed(2)} Solar masses'
          : 'Unknown',
    };

    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: data.entries
              .map((entry) => _buildDataRow(entry.key, entry.value))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getShortMethod(String? method) {
    if (method == null) return 'Unknown';
    final shortMethods = {
      'Transit': 'Transit',
      'Radial Velocity': 'RV',
      'Imaging': 'Imaging',
      'Microlensing': 'Micro',
      'Transit Timing Variations': 'TTV',
      'Eclipse Timing Variations': 'ETV',
      'Pulsar Timing': 'Pulsar',
      'Astrometry': 'Astrom',
    };
    return shortMethods[method] ??
        method.substring(0, method.length > 8 ? 8 : method.length);
  }

  void _shareplanet() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.planet.name}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _open3DWorldViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Planet3DWorldViewer(planet: widget.planet, biome: _biome),
        ),
      ),
    );
  }

  void _openAI3DViewer() {
    // Show "Coming Soon" message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚀 Coming Soon!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'AI-Generated 3D planets are under development',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9D4EDD),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Color _getBiomeColor(Biome biome) {
    switch (biome.type) {
      case 'Ocean World':
        return const Color(0xFF0984E3);
      case 'Desert World':
        return const Color(0xFFFDCB6E);
      case 'Ice World':
        return const Color(0xFF74B9FF);
      case 'Volcanic World':
        return const Color(0xFFD63031);
      case 'Tropical Paradise':
        return AppTheme.secondaryColor;
      case 'Temperate World':
        return const Color(0xFF55EFC4);
      case 'Tundra World':
        return const Color(0xFFB2BEC3);
      case 'Barren Rock':
        return const Color(0xFF636E72);
      case 'Gas Giant':
        return const Color(0xFFA29BFE);
      case 'Rocky Planet':
        return const Color(0xFF6C5CE7);
      default:
        return AppTheme.primaryColor;
    }
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
