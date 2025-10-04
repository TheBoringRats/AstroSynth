import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/biome.dart';
import '../models/life_form.dart';
import '../models/planet.dart';
import '../services/evolution_engine.dart';
import '../services/habitability_calculator.dart';

/// Interactive screen simulating evolution on an exoplanet over 4 billion years
///
/// This is a unique feature that shows how life might develop based on:
/// - Planet's habitability score
/// - Biome type and conditions
/// - Time elapsed since formation
class EvolutionSimulatorScreen extends StatefulWidget {
  final Planet planet;
  final Biome biome;

  const EvolutionSimulatorScreen({
    super.key,
    required this.planet,
    required this.biome,
  });

  @override
  State<EvolutionSimulatorScreen> createState() =>
      _EvolutionSimulatorScreenState();
}

class _EvolutionSimulatorScreenState extends State<EvolutionSimulatorScreen>
    with SingleTickerProviderStateMixin {
  final EvolutionEngine _engine = EvolutionEngine();
  final HabitabilityCalculator _calculator = HabitabilityCalculator();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Timeline state
  double _yearsElapsed = 0; // 0 to 4000 million years
  List<LifeForm> _currentLifeForms = [];
  List<EvolutionaryEvent> _events = [];
  double _habitabilityScore = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0; // 1x, 10x, 100x, 1000x

  @override
  void initState() {
    super.initState();

    // Calculate habitability
    if (widget.planet.hasSufficientData) {
      final result = _calculator.calculateHabitability(widget.planet);
      _habitabilityScore = result.overallScore;
    } else {
      _habitabilityScore = 50; // Default for insufficient data
    }

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start at 500 million years (when life begins)
    _yearsElapsed = 500;
    _updateEvolution();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateEvolution() {
    setState(() {
      _currentLifeForms = _engine.simulateEvolution(
        planet: widget.planet,
        yearsElapsed: _yearsElapsed.round(),
        biomeType: widget.biome.type,
        habitability: _habitabilityScore,
      );

      _events = _engine.generateEvents(
        planet: widget.planet,
        yearsElapsed: _yearsElapsed.round(),
        biomeType: widget.biome.type,
        habitability: _habitabilityScore,
      );
    });

    // Trigger fade animation
    _animationController.reset();
    _animationController.forward();
  }

  void _onTimelineChanged(double value) {
    setState(() {
      _yearsElapsed = value;
    });
    _updateEvolution();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(Duration(milliseconds: (50 / _playbackSpeed).round()), () {
      if (!_isPlaying || !mounted) return;

      if (_yearsElapsed < 4000) {
        setState(() {
          _yearsElapsed += _playbackSpeed * 10; // Increase by 10 million years
          if (_yearsElapsed > 4000) _yearsElapsed = 4000;
        });
        _updateEvolution();
        _startAutoPlay(); // Continue playing
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _resetSimulation() {
    setState(() {
      _yearsElapsed = 0;
      _isPlaying = false;
    });
    _updateEvolution();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              _getBiomeColor(widget.biome).withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPlanetHeader(),
                      _buildTimelineControls(),
                      _buildEvolutionProgress(),
                      _buildCurrentStageDisplay(),
                      _buildEvolutionaryEvents(),
                      const SizedBox(height: AppConstants.defaultPadding * 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.science, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolution Simulator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.planet.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.textSecondary),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetHeader() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: _getBiomeColor(widget.biome).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getBiomeColor(widget.biome).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getBiomeIcon(widget.biome),
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.biome.type,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Habitability: ${_habitabilityScore.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.biome.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineControls() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_yearsElapsed.round()} Million Years',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.textMuted.withOpacity(0.3),
              thumbColor: AppTheme.accentColor,
              overlayColor: AppTheme.accentColor.withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _yearsElapsed,
              min: 0,
              max: 4000,
              divisions: 80,
              onChanged: _isPlaying ? null : _onTimelineChanged,
            ),
          ),

          const SizedBox(height: 8),

          // Time markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeMarker('0'),
              _buildTimeMarker('1B'),
              _buildTimeMarker('2B'),
              _buildTimeMarker('3B'),
              _buildTimeMarker('4B'),
            ],
          ),

          const SizedBox(height: 16),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset button
              IconButton(
                icon: const Icon(
                  Icons.restart_alt,
                  color: AppTheme.textSecondary,
                ),
                onPressed: _resetSimulation,
                tooltip: 'Reset',
              ),

              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayback,
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                ),
              ),

              // Speed selector
              PopupMenuButton<double>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${_playbackSpeed.toStringAsFixed(0)}x',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                onSelected: (speed) {
                  setState(() {
                    _playbackSpeed = speed;
                  });
                },
                itemBuilder: (context) => [
                  _buildSpeedMenuItem(1.0, '1x - Slow'),
                  _buildSpeedMenuItem(10.0, '10x - Normal'),
                  _buildSpeedMenuItem(100.0, '100x - Fast'),
                  _buildSpeedMenuItem(1000.0, '1000x - Ultra'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed, String label) {
    return PopupMenuItem(
      value: speed,
      child: Row(
        children: [
          if (speed == _playbackSpeed)
            const Icon(Icons.check, color: AppTheme.primaryColor, size: 18)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildTimeMarker(String label) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, fontSize: 10),
    );
  }

  Widget _buildEvolutionProgress() {
    final stageProgress = _engine.getStageProgress(_currentLifeForms);

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolutionary Stages',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: EvolutionaryStage.values.map((stage) {
              final reached = stageProgress[stage] ?? false;
              final icon = LifeForm(
                id: '',
                name: '',
                stage: stage,
                description: '',
                traits: [],
                complexity: 0,
                biomeType: '',
                yearEvolved: 0,
              ).stageIcon;

              return Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: reached
                          ? AppTheme.primaryColor
                          : AppTheme.textMuted.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(
                          fontSize: 24,
                          color: reached ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      _getStageShortName(stage),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: reached
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getStageShortName(EvolutionaryStage stage) {
    switch (stage) {
      case EvolutionaryStage.singleCell:
        return 'Single-Cell';
      case EvolutionaryStage.multiCell:
        return 'Multi-Cell';
      case EvolutionaryStage.aquatic:
        return 'Aquatic';
      case EvolutionaryStage.land:
        return 'Land';
      case EvolutionaryStage.intelligence:
        return 'Intelligence';
    }
  }

  Widget _buildCurrentStageDisplay() {
    if (_currentLifeForms.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Column(
          children: [
            Icon(
              _yearsElapsed < 500 ? Icons.hourglass_empty : Icons.cancel,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _yearsElapsed < 500 ? 'Too Early for Life' : 'No Life Detected',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _engine.getEvolutionSummary(
                yearsElapsed: _yearsElapsed.round(),
                habitability: _habitabilityScore,
                biomeType: widget.biome.type,
                lifeForms: _currentLifeForms,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Life Forms Present',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _engine.getEvolutionSummary(
                yearsElapsed: _yearsElapsed.round(),
                habitability: _habitabilityScore,
                biomeType: widget.biome.type,
                lifeForms: _currentLifeForms,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ...(_currentLifeForms.map(_buildLifeFormCard).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeFormCard(LifeForm lifeForm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(lifeForm.stageIcon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lifeForm.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${lifeForm.stageDisplayName} • ${lifeForm.complexityCategory}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lifeForm.complexity.toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lifeForm.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lifeForm.traits.map((trait) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getBiomeColor(widget.biome).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getBiomeColor(widget.biome).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  trait,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionaryEvents() {
    final visibleEvents =
        _events.where((event) => event.yearOccurred <= _yearsElapsed).toList()
          ..sort((a, b) => b.yearOccurred.compareTo(a.yearOccurred));

    if (visibleEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Major Events',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...visibleEvents.map(_buildEventCard).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(EvolutionaryEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(
          color: event.isMassExtinction
              ? AppTheme.warningColor.withOpacity(0.5)
              : AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${event.yearOccurred} MYA',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get biome-specific colors
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

  /// Helper method to get biome-specific icons
  String _getBiomeIcon(Biome biome) {
    switch (biome.type) {
      case 'Ocean World':
        return '🌊';
      case 'Desert World':
        return '🏜️';
      case 'Ice World':
        return '❄️';
      case 'Volcanic World':
        return '🌋';
      case 'Tropical Paradise':
        return '🌴';
      case 'Temperate World':
        return '🌳';
      case 'Tundra World':
        return '🏔️';
      case 'Barren Rock':
        return '🪨';
      case 'Gas Giant':
        return '🌪️';
      case 'Rocky Planet':
        return '⛰️';
      default:
        return '🌍';
    }
  }
}
