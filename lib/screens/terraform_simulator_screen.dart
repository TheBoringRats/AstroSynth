import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/biome.dart';
import '../models/enhanced_habitability_result.dart';
import '../models/planet.dart';
import '../services/enhanced_habitability_calculator.dart';
import '../services/terraforming_engine.dart';
import '../widgets/habitability_spider_chart.dart';
import '../widgets/planet_3d_viewer.dart';

/// Interactive terraform simulator screen
/// Users can adjust planet parameters and see real-time habitability changes
class TerraformSimulatorScreen extends StatefulWidget {
  final Planet planet;

  const TerraformSimulatorScreen({super.key, required this.planet});

  @override
  State<TerraformSimulatorScreen> createState() =>
      _TerraformSimulatorScreenState();
}

class _TerraformSimulatorScreenState extends State<TerraformSimulatorScreen>
    with SingleTickerProviderStateMixin {
  late TerraformParameters _params;
  late EnhancedHabitabilityResult _originalResult;
  late EnhancedHabitabilityResult _currentResult;
  late TabController _tabController;

  final TerraformingEngine _engine = TerraformingEngine();
  final EnhancedHabitabilityCalculator _calculator =
      EnhancedHabitabilityCalculator();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize parameters
    _params = TerraformParameters.fromPlanet(widget.planet);

    // Calculate original habitability
    _originalResult = _calculator.calculateHabitability(widget.planet);
    _currentResult = _originalResult;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Recalculate habitability when parameters change
  void _updateHabitability() {
    setState(() {
      _params.normalizeAtmosphere();
      _currentResult = _engine.calculateTerraformedHabitability(
        widget.planet,
        _params,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spaceBackgroundGradient),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildScoreComparison(),
                  _buildTabBar(),
                  _buildTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Terraform Simulator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _currentResult.color.withOpacity(0.3),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Reset button
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to original',
          onPressed: () {
            setState(() {
              _params.reset();
              _updateHabitability();
            });
          },
        ),
        // Save scenario button
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Save scenario',
          onPressed: () {
            _showSaveDialog();
          },
        ),
      ],
    );
  }

  Widget _buildScoreComparison() {
    final comparison = _engine.generateComparison(
      _originalResult,
      _currentResult,
    );
    final scoreDiff = comparison['scoreDifference'] as double;
    final isImproved = comparison['isImproved'] as bool;

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isImproved
                ? const Color(0xFF00B894).withOpacity(0.2)
                : const Color(0xFFFF7675).withOpacity(0.2),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isImproved ? const Color(0xFF00B894) : const Color(0xFFFF7675),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Original score
          Expanded(
            child: _buildScoreCard(
              'Original',
              _originalResult.overallScore,
              _originalResult.category,
              _originalResult.color,
            ),
          ),
          // Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              isImproved ? Icons.arrow_forward : Icons.arrow_downward,
              color: isImproved
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFF7675),
              size: 32,
            ),
          ),
          // Current score
          Expanded(
            child: _buildScoreCard(
              'Terraformed',
              _currentResult.overallScore,
              _currentResult.category,
              _currentResult.color,
            ),
          ),
          // Difference
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  (isImproved
                          ? const Color(0xFF00B894)
                          : const Color(0xFFFF7675))
                      .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  isImproved ? Icons.trending_up : Icons.trending_down,
                  color: isImproved
                      ? const Color(0xFF00B894)
                      : const Color(0xFFFF7675),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  '${isImproved ? '+' : ''}${scoreDiff.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: isImproved
                        ? const Color(0xFF00B894)
                        : const Color(0xFFFF7675),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    String label,
    double score,
    String category,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${score.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          category,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          textAlign: TextAlign.center,
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
          Tab(text: 'Atmosphere'),
          Tab(text: 'Physical'),
          Tab(text: 'Preview'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.55,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAtmosphereTab(),
          _buildPhysicalTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  Widget _buildAtmosphereTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breathability indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBreathabilityColor().withOpacity(0.1),
              border: Border.all(color: _getBreathabilityColor(), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getBreathabilityIcon(),
                  color: _getBreathabilityColor(),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _engine.getBreathability(_params),
                    style: TextStyle(
                      color: _getBreathabilityColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nitrogen
          _buildSlider(
            'N₂ (Nitrogen)',
            _params.nitrogenPercent,
            0,
            95,
            const Color(0xFF3498DB),
            (value) {
              setState(() {
                _params.nitrogenPercent = value;
                _updateHabitability();
              });
            },
          ),

          // Oxygen
          _buildSlider(
            'O₂ (Oxygen)',
            _params.oxygenPercent,
            0,
            40,
            const Color(0xFF2ECC71),
            (value) {
              setState(() {
                _params.oxygenPercent = value;
                _updateHabitability();
              });
            },
          ),

          // CO2
          _buildSlider(
            'CO₂ (Carbon Dioxide)',
            _params.carbonDioxidePercent,
            0,
            10,
            const Color(0xFFE67E22),
            (value) {
              setState(() {
                _params.carbonDioxidePercent = value;
                _updateHabitability();
              });
            },
          ),

          // Water Vapor
          _buildSlider(
            'H₂O (Water Vapor)',
            _params.waterVaporPercent,
            0,
            5,
            const Color(0xFF1ABC9C),
            (value) {
              setState(() {
                _params.waterVaporPercent = value;
                _updateHabitability();
              });
            },
          ),

          // Argon
          _buildSlider(
            'Ar (Argon)',
            _params.argonPercent,
            0,
            2,
            const Color(0xFF9B59B6),
            (value) {
              setState(() {
                _params.argonPercent = value;
                _updateHabitability();
              });
            },
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Total: ${_params.totalAtmosphere.toStringAsFixed(1)}%',
              style: TextStyle(
                color:
                    _params.totalAtmosphere > 105 ||
                        _params.totalAtmosphere < 95
                    ? Colors.red
                    : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Water coverage
          _buildSlider(
            'Water Coverage',
            _params.waterCoverage,
            0,
            100,
            const Color(0xFF1E90FF),
            (value) {
              setState(() {
                _params.waterCoverage = value;
                _updateHabitability();
              });
            },
            suffix: '%',
          ),

          // Orbital distance
          _buildSlider(
            'Orbital Distance',
            _params.orbitalDistance,
            0.1,
            5.0,
            const Color(0xFFFFA500),
            (value) {
              setState(() {
                _params.orbitalDistance = value;
                _updateHabitability();
              });
            },
            suffix: ' AU',
          ),

          // Planet mass
          _buildSlider(
            'Planet Mass',
            _params.planetMass,
            0.1,
            5.0,
            const Color(0xFF8B4513),
            (value) {
              setState(() {
                _params.planetMass = value;
                _updateHabitability();
              });
            },
            suffix: ' M⊕',
          ),

          // Planet radius
          _buildSlider(
            'Planet Radius',
            _params.planetRadius,
            0.3,
            3.0,
            const Color(0xFFFF6347),
            (value) {
              setState(() {
                _params.planetRadius = value;
                _updateHabitability();
              });
            },
            suffix: ' R⊕',
          ),

          // Moon toggle
          Card(
            color: AppTheme.cardBackground,
            child: SwitchListTile(
              title: const Text(
                'Has Large Moon',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Stabilizes axial tilt and creates tides',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              value: _params.hasMoon,
              onChanged: (value) {
                setState(() {
                  _params.hasMoon = value;
                  _updateHabitability();
                });
              },
              activeColor: const Color(0xFF00B894),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    // Calculate current biome using classify
    final biome = Biome.classify(
      temperature: 280.0, // Estimated temperature
      radius: _params.planetRadius,
      mass: _params.planetMass,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // 3D Preview
          SizedBox(
            height: 250,
            child: Planet3DViewer(
              planet: widget.planet,
              // biome: biome, // Parameter removed in mobile stub
            ),
          ),
          const SizedBox(height: 24),

          // Biome info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBiomeColor(biome).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getBiomeColor(biome)),
            ),
            child: Column(
              children: [
                Icon(
                  _getBiomeIcon(biome),
                  size: 48,
                  color: _getBiomeColor(biome),
                ),
                const SizedBox(height: 12),
                Text(
                  biome.type,
                  style: TextStyle(
                    color: _getBiomeColor(biome),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  biome.description,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Spider chart
          HabitabilitySpiderChart(result: _currentResult, size: 280),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Color color,
    ValueChanged<double> onChanged, {
    String suffix = '',
  }) {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(2)}$suffix',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              activeColor: color,
              inactiveColor: color.withOpacity(0.3),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Color _getBreathabilityColor() {
    final breathability = _engine.getBreathability(_params);
    switch (breathability) {
      case 'Breathable':
        return const Color(0xFF2ECC71);
      case 'Marginally Breathable':
        return const Color(0xFFF39C12);
      case 'Toxic':
        return const Color(0xFFE67E22);
      case 'Lethal':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  IconData _getBreathabilityIcon() {
    final breathability = _engine.getBreathability(_params);
    switch (breathability) {
      case 'Breathable':
        return Icons.check_circle;
      case 'Marginally Breathable':
        return Icons.warning_amber;
      case 'Toxic':
        return Icons.dangerous;
      case 'Lethal':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getBiomeColor(Biome biome) {
    switch (biome.type) {
      case 'Temperate':
        return const Color(0xFF2ECC71);
      case 'Ocean':
      case 'Water World':
        return const Color(0xFF3498DB);
      case 'Frozen':
      case 'Ice World':
        return const Color(0xFF00CED1);
      case 'Desert':
        return const Color(0xFFE67E22);
      case 'Volcanic':
      case 'Lava World':
        return const Color(0xFFE74C3C);
      case 'Barren':
      case 'Rocky':
        return const Color(0xFF95A5A6);
      default:
        return Colors.grey;
    }
  }

  IconData _getBiomeIcon(Biome biome) {
    switch (biome.type) {
      case 'Temperate':
        return Icons.wb_sunny;
      case 'Ocean':
      case 'Water World':
        return Icons.water;
      case 'Frozen':
      case 'Ice World':
        return Icons.ac_unit;
      case 'Desert':
        return Icons.wb_sunny_outlined;
      case 'Volcanic':
      case 'Lava World':
        return Icons.local_fire_department;
      case 'Barren':
      case 'Rocky':
        return Icons.landscape;
      default:
        return Icons.public;
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Scenario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Save this terraform scenario?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Scenario Name',
                hintText: 'e.g., "Earth-like Transformation"',
              ),
              onSubmitted: (name) {
                // TODO: Implement save functionality
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scenario saved!')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Scenario saved!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
