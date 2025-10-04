import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/planet.dart';
import '../services/planet_evolution_simulator.dart';
import '../widgets/planet_3d_viewer.dart';

/// Interactive time evolution screen showing planetary lifecycle
class TimeEvolutionScreen extends StatefulWidget {
  final Planet planet;

  const TimeEvolutionScreen({super.key, required this.planet});

  @override
  State<TimeEvolutionScreen> createState() => _TimeEvolutionScreenState();
}

class _TimeEvolutionScreenState extends State<TimeEvolutionScreen>
    with SingleTickerProviderStateMixin {
  final PlanetEvolutionSimulator _simulator = PlanetEvolutionSimulator();

  late List<PlanetSnapshot> _timeline;
  late AnimationController _animationController;
  int _currentStageIndex = 2; // Start at "Stable (Current)"
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Generate timeline with 50 data points
    _timeline = _simulator.generateTimeline(widget.planet, 50);

    // Animation controller for auto-play
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            if (_isPlaying) {
              setState(() {
                _currentStageIndex =
                    (_animationController.value * (_timeline.length - 1))
                        .round();
              });
            }
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _isPlaying) {
              _animationController.repeat();
            }
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  PlanetSnapshot get _currentSnapshot => _timeline[_currentStageIndex];

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.forward(
          from: _currentStageIndex / (_timeline.length - 1),
        );
      } else {
        _animationController.stop();
      }
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
                  _build3DPreview(),
                  _buildTimelineSlider(),
                  _buildPlayControls(),
                  _buildStageInfo(),
                  _buildParametersChart(),
                  _buildCharacteristics(),
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
      expandedHeight: 100,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Time Evolution: ${widget.planet.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getStageColor().withOpacity(0.3),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DPreview() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStageColor(), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Planet3DViewer(
          planet: widget.planet,
          // biome: _currentSnapshot.biome, // Parameter removed in mobile stub
        ),
      ),
    );
  }

  Widget _buildTimelineSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStageColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStageColor()),
                ),
                child: Text(
                  _currentSnapshot.formattedAge,
                  style: TextStyle(
                    color: _getStageColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getStageColor(),
              inactiveTrackColor: _getStageColor().withOpacity(0.3),
              thumbColor: _getStageColor(),
              overlayColor: _getStageColor().withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 8,
            ),
            child: Slider(
              value: _currentStageIndex.toDouble(),
              min: 0,
              max: (_timeline.length - 1).toDouble(),
              divisions: _timeline.length - 1,
              onChanged: (value) {
                setState(() {
                  _currentStageIndex = value.round();
                  _isPlaying = false;
                  _animationController.stop();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0 Years',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                '10 Billion Years',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayControls() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous stage
          IconButton(
            onPressed: _currentStageIndex > 0
                ? () {
                    setState(() {
                      _currentStageIndex--;
                      _isPlaying = false;
                      _animationController.stop();
                    });
                  }
                : null,
            icon: const Icon(Icons.skip_previous, size: 32),
            color: Colors.white,
          ),
          const SizedBox(width: 20),

          // Play/Pause
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStageColor(),
              boxShadow: [
                BoxShadow(
                  color: _getStageColor().withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),

          // Next stage
          IconButton(
            onPressed: _currentStageIndex < _timeline.length - 1
                ? () {
                    setState(() {
                      _currentStageIndex++;
                      _isPlaying = false;
                      _animationController.stop();
                    });
                  }
                : null,
            icon: const Icon(Icons.skip_next, size: 32),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStageInfo() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStageColor().withOpacity(0.2), AppTheme.cardBackground],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStageColor(), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStageIcon(), color: _getStageColor(), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentSnapshot.stage.name,
                  style: TextStyle(
                    color: _getStageColor(),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentSnapshot.stage.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                'Temperature',
                '${_currentSnapshot.temperature.toStringAsFixed(0)}K',
                Icons.thermostat,
              ),
              _buildInfoChip(
                'Habitability',
                '${_currentSnapshot.habitability.toStringAsFixed(0)}%',
                Icons.eco,
              ),
              _buildInfoChip(
                'Pressure',
                '${_currentSnapshot.atmosphere.pressure.toStringAsFixed(2)} atm',
                Icons.air,
              ),
              _buildInfoChip(
                'Star Phase',
                _currentSnapshot.stage.stellarPhase,
                Icons.wb_sunny,
              ),
              if (_currentSnapshot.hasOceans)
                _buildInfoChip('Has Oceans', '💧', Icons.water),
              if (_currentSnapshot.hasLife)
                _buildInfoChip('Has Life', '🌱', Icons.pets),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _getStageColor()),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParametersChart() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolution Over Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final billions = value / 10;
                        return Text(
                          '${billions.toStringAsFixed(0)}B',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
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
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
                lineBarsData: [
                  // Habitability line
                  LineChartBarData(
                    spots: _timeline
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(e.key.toDouble(), e.value.habitability),
                        )
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF2ECC71),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == _currentStageIndex) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF2ECC71),
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 2,
                          color: const Color(0xFF2ECC71),
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacteristics() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Characteristics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._currentSnapshot.stage.characteristics.map(
            (char) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: _getStageColor(), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      char,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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

  Color _getStageColor() {
    switch (_currentSnapshot.stage.name) {
      case 'Formation':
        return const Color(0xFFE74C3C); // Red
      case 'Early':
        return const Color(0xFFE67E22); // Orange
      case 'Stable (Current)':
        return const Color(0xFF2ECC71); // Green
      case 'Aging':
        return const Color(0xFFF39C12); // Yellow
      case 'End Stage':
        return const Color(0xFF95A5A6); // Gray
      default:
        return Colors.blue;
    }
  }

  IconData _getStageIcon() {
    switch (_currentSnapshot.stage.name) {
      case 'Formation':
        return Icons.local_fire_department;
      case 'Early':
        return Icons.blur_on;
      case 'Stable (Current)':
        return Icons.wb_sunny;
      case 'Aging':
        return Icons.warning_amber;
      case 'End Stage':
        return Icons.cancel;
      default:
        return Icons.public;
    }
  }
}
