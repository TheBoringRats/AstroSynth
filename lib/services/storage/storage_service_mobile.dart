import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'storage_service.dart';

/// Mobile/Desktop implementation using SQLite
class StorageServiceMobile implements StorageService {
  Database? _db;
  static const String _dbName = 'astrosynth_storage.db';
  static const String _tableName = 'key_value_store';

  @override
  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> setItem(String key, String value) async {
    await init();
    await _db!.insert(_tableName, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<String?> getItem(String key) async {
    await init();
    final result = await _db!.query(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  @override
  Future<void> removeItem(String key) async {
    await init();
    await _db!.delete(_tableName, where: 'key = ?', whereArgs: [key]);
  }

  @override
  Future<void> clear() async {
    await init();
    await _db!.delete(_tableName);
  }

  @override
  Future<List<String>> getAllKeys() async {
    await init();
    final result = await _db!.query(_tableName, columns: ['key']);
    return result.map((row) => row['key'] as String).toList();
  }
}
