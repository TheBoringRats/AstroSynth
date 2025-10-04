import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Mobile stub for planet card - shows simplified version without HTML canvas
class PlanetCard3DPreview extends StatelessWidget {
  final dynamic planet;

  const PlanetCard3DPreview({Key? key, required this.planet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, show message that user should use the web version
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.purple.shade900],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 48, color: Colors.white70),
              SizedBox(height: 8),
              Text(
                '3D Preview',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'View in detail page',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    
    // Mobile fallback - show icon
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.purple.shade900],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, size: 48, color: Colors.white70),
            SizedBox(height: 8),
            Text(
              '3D Preview',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Tap planet for details',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
