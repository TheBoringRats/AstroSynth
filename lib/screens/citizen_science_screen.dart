import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/light_curve.dart';
import '../services/light_curve_service.dart';

/// Citizen Science screen for analyzing light curves
///
/// Users can identify exoplanet transits by marking dips in brightness
class CitizenScienceScreen extends StatefulWidget {
  final String? userId;

  const CitizenScienceScreen({super.key, this.userId});

  @override
  State<CitizenScienceScreen> createState() => _CitizenScienceScreenState();
}

class _CitizenScienceScreenState extends State<CitizenScienceScreen> {
  final LightCurveService _service = LightCurveService();

  late List<LightCurve> _availableCurves;
  late LightCurve _currentCurve;
  late CitizenScienceStats _userStats;

  int _currentCurveIndex = 0;
  List<UserObservation> _currentObservations = [];

  // Marking state
  bool _isMarking = false;
  double? _markStartTime;
  double? _markEndTime;

  @override
  void initState() {
    super.initState();

    // Initialize with training set
    _availableCurves = _service.generateTrainingSet(count: 10);
    _currentCurve = _availableCurves[0];

    // Initialize user stats
    _userStats = CitizenScienceStats.empty(widget.userId ?? 'guest');
  }

  void _nextCurve() {
    if (_currentCurveIndex < _availableCurves.length - 1) {
      setState(() {
        _currentCurveIndex++;
        _currentCurve = _availableCurves[_currentCurveIndex];
        _currentObservations = [];
        _markStartTime = null;
        _markEndTime = null;
        _isMarking = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousCurve() {
    if (_currentCurveIndex > 0) {
      setState(() {
        _currentCurveIndex--;
        _currentCurve = _availableCurves[_currentCurveIndex];
        _currentObservations = [];
        _markStartTime = null;
        _markEndTime = null;
        _isMarking = false;
      });
    }
  }

  void _submitObservation() {
    if (_markStartTime == null || _markEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark a transit first!')),
      );
      return;
    }

    // Create observation
    final observation = UserObservation(
      id: 'obs_${DateTime.now().millisecondsSinceEpoch}',
      lightCurveId: _currentCurve.id,
      userId: widget.userId ?? 'guest',
      startTime: _markStartTime!,
      endTime: _markEndTime!,
      timestamp: DateTime.now(),
      confidence: 0.8,
    );

    // Validate against ground truth
    final validated = _service.validateObservation(observation, _currentCurve);

    // Update stats
    setState(() {
      _currentObservations.add(validated);
      _userStats = _service.updateStats(_userStats, validated);
    });

    // Show feedback
    _showFeedback(validated);
  }

  void _showFeedback(UserObservation observation) {
    if (observation.isCorrect == null) {
      // Unknown - no ground truth
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observation recorded! (No ground truth available)'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final isCorrect = observation.isCorrect!;
    final accuracy = observation.accuracy!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              isCorrect ? 'Correct!' : 'Not Quite',
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCorrect
                  ? 'Great job! You correctly identified the transit.'
                  : 'Your marking didn\'t match the actual transit closely enough.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Accuracy: ',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                Text(
                  '${(accuracy * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: accuracy > 0.7
                        ? Colors.green
                        : accuracy > 0.4
                        ? Colors.orange
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Points Earned: ',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                Text(
                  '+${10 + (accuracy * 10).round()}',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextCurve();
            },
            child: const Text('Next Light Curve'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.accentColor, size: 32),
            SizedBox(width: 12),
            Text(
              'Training Complete!',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve completed all training light curves!',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Observations', _userStats.totalObservations),
            _buildStatRow('Correct', _userStats.correctObservations),
            _buildStatRow(
              'Accuracy',
              '${_userStats.accuracyPercentage.toStringAsFixed(1)}%',
            ),
            _buildStatRow('Total Points', _userStats.totalPoints),
            _buildStatRow('Level', _userStats.level),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.science, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Citizen Science'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTutorial,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCurveInfo(),
                  _buildLightCurveChart(),
                  _buildControls(),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      color: AppTheme.cardBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            'Level',
            _userStats.level.toString(),
            Icons.military_tech,
            AppTheme.accentColor,
          ),
          _buildQuickStat(
            'Points',
            _userStats.totalPoints.toString(),
            Icons.stars,
            AppTheme.primaryColor,
          ),
          _buildQuickStat(
            'Accuracy',
            '${_userStats.accuracyPercentage.toStringAsFixed(0)}%',
            Icons.trending_up,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentCurveIndex + 1) / _availableCurves.length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 8,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Light Curve ${_currentCurveIndex + 1} of ${_availableCurves.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                'Difficulty: ${_currentCurve.difficultyLevel}',
                style: TextStyle(
                  color: _getDifficultyColor(_currentCurve.difficultyLevel),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.textMuted.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      case 'Expert':
        return Colors.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildCurveInfo() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentCurve.starName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Observed by: ${_currentCurve.instrument}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Text(
            'Duration: ${_currentCurve.observationDuration.toStringAsFixed(1)} days',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLightCurveChart() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      height: 300,
      child: GestureDetector(
        onTapDown: (details) {
          if (!_isMarking) return;

          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);

          // Convert tap position to time value
          // This is a simplified conversion - actual implementation would need
          // to account for chart dimensions and scaling
          setState(() {
            if (_markStartTime == null) {
              _markStartTime =
                  localPosition.dx /
                  renderBox.size.width *
                  _currentCurve.observationDuration;
            } else if (_markEndTime == null) {
              _markEndTime =
                  localPosition.dx /
                  renderBox.size.width *
                  _currentCurve.observationDuration;
            }
          });
        },
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 0.01,
              verticalInterval: _currentCurve.observationDuration / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.textMuted.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: AppTheme.textMuted.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Time (days)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: _currentCurve.observationDuration / 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: const Text(
                  'Brightness',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 0.02,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: AppTheme.textMuted.withOpacity(0.3)),
            ),
            minX: _currentCurve.minTime,
            maxX: _currentCurve.maxTime,
            minY: _currentCurve.minBrightness - 0.01,
            maxY: _currentCurve.maxBrightness + 0.01,
            lineBarsData: [
              // Main light curve
              LineChartBarData(
                spots: _currentCurve.dataPoints
                    .map((p) => FlSpot(p.time, p.brightness))
                    .toList(),
                isCurved: false,
                color: AppTheme.primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              // User markings
              if (_markStartTime != null && _markEndTime != null)
                LineChartBarData(
                  spots: [
                    FlSpot(_markStartTime!, _currentCurve.minBrightness),
                    FlSpot(_markEndTime!, _currentCurve.minBrightness),
                  ],
                  isCurved: false,
                  color: Colors.red,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isMarking = !_isMarking;
                    if (!_isMarking) {
                      _markStartTime = null;
                      _markEndTime = null;
                    }
                  });
                },
                icon: Icon(_isMarking ? Icons.clear : Icons.edit),
                label: Text(_isMarking ? 'Cancel' : 'Mark Transit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMarking
                      ? Colors.red
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _markStartTime != null && _markEndTime != null
                    ? _submitObservation
                    : null,
                icon: const Icon(Icons.check),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentCurveIndex > 0 ? _previousCurve : null,
                icon: const Icon(Icons.arrow_back),
                color: AppTheme.textSecondary,
                tooltip: 'Previous',
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _markStartTime = null;
                    _markEndTime = null;
                    _isMarking = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                color: AppTheme.textSecondary,
                tooltip: 'Reset',
              ),
              IconButton(
                onPressed: _currentCurveIndex < _availableCurves.length - 1
                    ? _nextCurve
                    : null,
                icon: const Icon(Icons.arrow_forward),
                color: AppTheme.textSecondary,
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'How to Analyze',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstructionStep('1', 'Look for dips in the light curve'),
          _buildInstructionStep(
            '2',
            'Tap "Mark Transit" and tap start/end points',
          ),
          _buildInstructionStep('3', 'Submit your observation'),
          _buildInstructionStep('4', 'Get instant feedback and points!'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Row(
          children: [
            Icon(Icons.school, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Tutorial', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What is a Light Curve?',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'A light curve shows how a star\'s brightness changes over time. When a planet passes in front of its star (a "transit"), it blocks some light, creating a dip.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              SizedBox(height: 16),
              Text(
                'Your Mission:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Identify transit dips in the light curve\n'
                '• Mark the start and end of each transit\n'
                '• Submit your observations\n'
                '• Earn points and badges!\n\n'
                'Real scientists use this same method to discover exoplanets!',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
