import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Script to fetch all exoplanets from NASA API in batches and save as JSON
void main() async {
  print('🌍 Fetching exoplanets from NASA Exoplanet Archive in batches...');
  print('');

  final baseUrl = 'https://exoplanetarchive.ipac.caltech.edu/TAP/sync';
  final batchSize = 100;
  final allPlanets = <dynamic>[];
  var offset = 0;
  var batchNumber = 1;

  while (true) {
    final query =
        '''
SELECT pl_name,hostname,sy_dist,pl_orbper,pl_rade,pl_bmasse,pl_eqt,pl_orbsmax,pl_orbeccen,st_spectype,st_teff,st_rad,st_mass,disc_year,discoverymethod,ra,dec,default_flag FROM ps WHERE default_flag=1 ORDER BY disc_year DESC
'''
            .trim();

    // Use MAXREC and OFFSET as URL parameters (TAP-specific)
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'query': query,
        'format': 'json',
        'maxrec': batchSize.toString(),
        'offset': offset.toString(),
      },
    );

    try {
      print(
        '📦 Fetching batch $batchNumber (offset: $offset, limit: $batchSize)...',
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'AstroSynth/1.0.0 (NASA Space Apps Challenge)',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> batch = json.decode(response.body);

        if (batch.isEmpty) {
          print('✅ No more planets found. Fetch complete!');
          break;
        }

        allPlanets.addAll(batch);
        print('   ✓ Got ${batch.length} planets (Total: ${allPlanets.length})');

        offset += batchSize;
        batchNumber++;

        // Small delay to be nice to NASA's servers
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        final errorBody = response.body.substring(
          0,
          200.clamp(0, response.body.length),
        );
        print('❌ HTTP ${response.statusCode}: $errorBody');
        break;
      }
    } catch (e) {
      print('❌ Error in batch $batchNumber: $e');
      print(
        '⚠️ Continuing with ${allPlanets.length} planets fetched so far...',
      );
      break;
    }
  }

  if (allPlanets.isEmpty) {
    print('❌ No planets fetched. Exiting.');
    exit(1);
  }

  print('');
  print('📥 Total planets fetched: ${allPlanets.length}');
  print('');

  // Save as JSON file
  try {
    final outputPath = 'assets/data/exoplanets_nasa.json';
    final file = File(outputPath);

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    print('💾 Saving to: $outputPath');

    // Write formatted JSON
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(allPlanets),
    );

    print('✅ Saved successfully!');
    print(
      '📊 File size: ${(await file.length() / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    // Print sample data
    if (allPlanets.isNotEmpty) {
      print('');
      print('📋 Sample planet data (first planet):');
      final first = allPlanets[0];
      print('   Name: ${first['pl_name']}');
      print('   Host Star: ${first['hostname']}');
      print('   Discovery Year: ${first['disc_year']}');
      print('   Method: ${first['discoverymethod']}');
      print('   Radius: ${first['pl_rade']} Earth radii');
      print('   Mass: ${first['pl_bmasse']} Earth masses');
    }

    print('');
    print('🎉 Done! You can now use this JSON file in your app.');
    print('');
    print('Next steps:');
    print(
      '1. Update pubspec.yaml to include: assets/data/exoplanets_nasa.json',
    );
    print('2. Update unified_data_service.dart to load JSON instead of CSV');
    print('3. Run the app to see all ${allPlanets.length} planets!');
  } catch (e) {
    print('❌ Error saving file: $e');
    exit(1);
  }
}
