import 'package:flutter/material.dart';

/// Stub for mobile - planet card without 3D preview
class PlanetCard extends StatelessWidget {
  final dynamic planet;
  final VoidCallback? onTap;

  const PlanetCard({
    Key? key,
    required this.planet,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planet.displayName ?? 'Unknown Planet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.purple.shade800],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.language, size: 64, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
