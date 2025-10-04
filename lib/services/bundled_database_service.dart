import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service to copy bundled SQLite database to app data directory
/// This allows us to ship a pre-populated database with the app
class BundledDatabaseService {
  static final BundledDatabaseService _instance =
      BundledDatabaseService._internal();
  factory BundledDatabaseService() => _instance;
  BundledDatabaseService._internal();

  bool _isInitialized = false;

  /// Copy bundled database to app data directory if it doesn't exist
  Future<bool> initializeBundledDatabase() async {
    if (_isInitialized) return true;
    if (kIsWeb) {
      print('[DB] Web platform - skipping bundled SQLite database');
      return false;
    }

    try {
      final dbPath = await getDatabasesPath();
      final targetPath = join(dbPath, 'exoplanets_bundled.db');

      // Check if database already exists
      final exists = await databaseExists(targetPath);
      if (exists) {
        print('[DB] Bundled database already exists at: $targetPath');
        _isInitialized = true;
        return true;
      }

      print('[DB] Copying bundled database from assets...');

      // Load database from assets as bytes
      final ByteData data = await rootBundle.load('assets/data/exoplanets.db');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write to app data directory
      await Directory(dbPath).create(recursive: true);
      await File(targetPath).writeAsBytes(bytes, flush: true);

      print('[DB] Successfully copied bundled database to: $targetPath');
      print(
        '[DB] Database size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      print('[ERROR] Failed to copy bundled database: $e');
      return false;
    }
  }

  /// Get the path to the bundled database
  Future<String> getBundledDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'exoplanets_bundled.db');
  }

  /// Open the bundled database directly
  Future<Database?> openBundledDatabase() async {
    try {
      final path = await getBundledDatabasePath();
      final exists = await databaseExists(path);

      if (!exists) {
        print('[DB] Bundled database not found, initializing...');
        await initializeBundledDatabase();
      }

      return await openDatabase(path, readOnly: true);
    } catch (e) {
      print('[ERROR] Failed to open bundled database: $e');
      return null;
    }
  }

  /// Check if bundled database is available
  Future<bool> isBundledDatabaseAvailable() async {
    if (kIsWeb) return false;

    try {
      final path = await getBundledDatabasePath();
      return await databaseExists(path);
    } catch (e) {
      return false;
    }
  }

  /// Get total planet count from bundled database
  Future<int> getBundledPlanetCount() async {
    try {
      final db = await openBundledDatabase();
      if (db == null) return 0;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM planets');
      await db.close();

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('[ERROR] Failed to get planet count: $e');
      return 0;
    }
  }
}
