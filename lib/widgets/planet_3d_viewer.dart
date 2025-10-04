import 'package:flutter/material.dart';

/// Stub for mobile - basic 3D viewer placeholder
class Planet3DViewer extends StatelessWidget {
  final dynamic planet;
  
  const Planet3DViewer({Key? key, required this.planet}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, size: 100, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              '3D Viewer',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              'Available on Web Version',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
