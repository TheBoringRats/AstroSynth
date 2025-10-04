import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/atmospheric_profile.dart';

/// Pie chart widget for displaying atmospheric gas composition
class AtmospherePieChart extends StatelessWidget {
  final AtmosphericProfile atmosphere;
  final double size;

  const AtmospherePieChart({
    super.key,
    required this.atmosphere,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sections: _buildSections(),
          centerSpaceRadius: size * 0.25, // Donut chart
          sectionsSpace: 2,
          borderData: FlBorderData(show: false),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Add touch interaction if needed
            },
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sortedGases = atmosphere.sortedGases;
    final colors = _getGasColors();

    return sortedGases.map((entry) {
      final gasName = entry.key;
      final percentage = entry.value;
      final color = colors[gasName] ?? _getRandomColor();

      return PieChartSectionData(
        value: percentage,
        title: percentage > 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: size * 0.35,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
        ),
        badgeWidget: percentage > 5.0
            ? null
            : _buildSmallBadge(gasName.split(' ')[0]), // Show gas symbol
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildSmallBadge(String gasSymbol) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        gasSymbol,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Get scientifically accurate colors for common gases
  Map<String, Color> _getGasColors() {
    return {
      'N₂ (Nitrogen)': const Color(0xFF3498DB), // Blue
      'O₂ (Oxygen)': const Color(0xFF2ECC71), // Green
      'CO₂ (Carbon Dioxide)': const Color(0xFFE67E22), // Orange
      'H₂O (Water Vapor)': const Color(0xFF1ABC9C), // Turquoise
      'Ar (Argon)': const Color(0xFF9B59B6), // Purple
      'SO₂ (Sulfur Dioxide)': const Color(0xFFE74C3C), // Red
      'CH₄ (Methane)': const Color(0xFFF39C12), // Yellow-orange
      'H₂ (Hydrogen)': const Color(0xFFECF0F1), // Light gray
      'He (Helium)': const Color(0xFFBDC3C7), // Gray
      'NH₃ (Ammonia)': const Color(0xFF16A085), // Teal
      'H₂S (Hydrogen Sulfide)': const Color(0xFF8E44AD), // Dark purple
      'Ne (Neon)': const Color(0xFFFF6B6B), // Light red
      'Volcanic Ash': const Color(0xFF34495E), // Dark gray
      'Trace Gases': const Color(0xFF7F8C8D), // Medium gray
      'Trace Solar Wind': const Color(0xFF95A5A6), // Light gray
      'Trace Compounds': const Color(0xFF85929E), // Steel gray
      'H₂O (Water Ice)': const Color(0xFF85C1E9), // Light blue
    };
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
      const Color(0xFFF39C12),
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}

/// Legend widget for the atmospheric composition pie chart
class AtmosphereLegend extends StatelessWidget {
  final AtmosphericProfile atmosphere;

  const AtmosphereLegend({super.key, required this.atmosphere});

  @override
  Widget build(BuildContext context) {
    final sortedGases = atmosphere.sortedGases;
    final colors = _getGasColors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedGases.map((entry) {
        final gasName = entry.key;
        final percentage = entry.value;
        final color = colors[gasName] ?? Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  gasName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, Color> _getGasColors() {
    return {
      'N₂ (Nitrogen)': const Color(0xFF3498DB),
      'O₂ (Oxygen)': const Color(0xFF2ECC71),
      'CO₂ (Carbon Dioxide)': const Color(0xFFE67E22),
      'H₂O (Water Vapor)': const Color(0xFF1ABC9C),
      'Ar (Argon)': const Color(0xFF9B59B6),
      'SO₂ (Sulfur Dioxide)': const Color(0xFFE74C3C),
      'CH₄ (Methane)': const Color(0xFFF39C12),
      'H₂ (Hydrogen)': const Color(0xFFECF0F1),
      'He (Helium)': const Color(0xFFBDC3C7),
      'NH₃ (Ammonia)': const Color(0xFF16A085),
      'H₂S (Hydrogen Sulfide)': const Color(0xFF8E44AD),
      'Ne (Neon)': const Color(0xFFFF6B6B),
      'Volcanic Ash': const Color(0xFF34495E),
      'Trace Gases': const Color(0xFF7F8C8D),
      'Trace Solar Wind': const Color(0xFF95A5A6),
      'Trace Compounds': const Color(0xFF85929E),
      'H₂O (Water Ice)': const Color(0xFF85C1E9),
    };
  }
}

/// Breathability indicator widget
class BreathabilityIndicator extends StatelessWidget {
  final AtmosphericProfile atmosphere;

  const BreathabilityIndicator({super.key, required this.atmosphere});

  @override
  Widget build(BuildContext context) {
    final color = _getBreathabilityColor();
    final icon = _getBreathabilityIcon();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  atmosphere.breathability,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBreathabilityDescription(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBreathabilityColor() {
    switch (atmosphere.breathability) {
      case 'Breathable':
        return const Color(0xFF2ECC71); // Green
      case 'Marginally Breathable':
        return const Color(0xFFF39C12); // Yellow
      case 'Toxic':
        return const Color(0xFFE67E22); // Orange
      case 'Lethal':
        return const Color(0xFFE74C3C); // Red
      default:
        return Colors.grey;
    }
  }

  IconData _getBreathabilityIcon() {
    switch (atmosphere.breathability) {
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

  String _getBreathabilityDescription() {
    switch (atmosphere.breathability) {
      case 'Breathable':
        return 'Humans could breathe without equipment';
      case 'Marginally Breathable':
        return 'Breathing possible but supplemental O₂ recommended';
      case 'Toxic':
        return 'Toxic gases present - protective gear required';
      case 'Lethal':
        return 'Completely unbreathable - sealed suit mandatory';
      default:
        return 'Breathability unknown';
    }
  }
}
