import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/enhanced_habitability_result.dart';

/// Spider/Radar chart for visualizing 8 habitability factors
class HabitabilitySpiderChart extends StatelessWidget {
  final EnhancedHabitabilityResult result;
  final double size;

  const HabitabilitySpiderChart({
    super.key,
    required this.result,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpiderChartPainter(
          factorScores: result.factorScores,
          habitabilityColor: result.color,
        ),
        child: Container(), // Empty container for the chart
      ),
    );
  }
}

class _SpiderChartPainter extends CustomPainter {
  final Map<String, double> factorScores;
  final Color habitabilityColor;

  _SpiderChartPainter({
    required this.factorScores,
    required this.habitabilityColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 60;

    // Draw background grid circles (25%, 50%, 75%, 100%)
    _drawGridCircles(canvas, center, radius);

    // Draw axes for each factor
    _drawAxes(canvas, center, radius);

    // Draw labels for each factor
    _drawLabels(canvas, center, radius, size);

    // Draw the actual data polygon
    _drawDataPolygon(canvas, center, radius);

    // Draw score points
    _drawDataPoints(canvas, center, radius);
  }

  void _drawGridCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 4 concentric circles (25%, 50%, 75%, 100%)
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), paint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.5;

    final angleStep = (2 * math.pi) / factorScores.length;

    for (int i = 0; i < factorScores.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep); // Start from top
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    final angleStep = (2 * math.pi) / factorScores.length;
    final labels = factorScores.keys.toList();

    for (int i = 0; i < labels.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final labelRadius = radius + 35;

      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: 80);

      // Center the text around the point
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );

      // Draw score value
      final score = factorScores[labels[i]]!;
      final scorePainter = TextPainter(
        text: TextSpan(
          text: '${score.toInt()}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      scorePainter.layout();
      scorePainter.paint(
        canvas,
        Offset(x - scorePainter.width / 2, y + textPainter.height / 2 + 2),
      );
    }
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double radius) {
    final path = Path();
    final angleStep = (2 * math.pi) / factorScores.length;
    final scores = factorScores.values.toList();

    // Create path for the polygon
    for (int i = 0; i < scores.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final score = scores[i];
      final pointRadius = radius * (score / 100); // Scale by score

      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill the polygon with semi-transparent color
    final fillPaint = Paint()
      ..color = habitabilityColor.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw the polygon outline
    final strokePaint = Paint()
      ..color = habitabilityColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, strokePaint);
  }

  void _drawDataPoints(Canvas canvas, Offset center, double radius) {
    final angleStep = (2 * math.pi) / factorScores.length;
    final scores = factorScores.values.toList();

    final pointPaint = Paint()
      ..color = habitabilityColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < scores.length; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final score = scores[i];
      final pointRadius = radius * (score / 100);

      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);

      // Draw point
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpiderChartPainter oldDelegate) {
    return oldDelegate.factorScores != factorScores ||
        oldDelegate.habitabilityColor != habitabilityColor;
  }
}

/// Compact legend showing all 8 factors with their scores
class HabitabilityFactorList extends StatelessWidget {
  final EnhancedHabitabilityResult result;

  const HabitabilityFactorList({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result.factorScores.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // Factor name
              Expanded(
                flex: 3,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Score bar
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Background bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar
                    FractionallySizedBox(
                      widthFactor: entry.value / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getScoreColor(entry.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Score value
              SizedBox(
                width: 35,
                child: Text(
                  '${entry.value.toInt()}',
                  style: TextStyle(
                    color: _getScoreColor(entry.value),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF00B894);
    if (score >= 60) return const Color(0xFF55EFC4);
    if (score >= 40) return const Color(0xFFFDCB6E);
    return const Color(0xFFFF7675);
  }
}
