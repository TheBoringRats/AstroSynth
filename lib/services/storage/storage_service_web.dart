import 'dart:html' as html;
import 'storage_service.dart';

/// Web implementation using IndexedDB
class StorageServiceWeb implements StorageService {
  html.Database? _db;
  static const String _dbName = 'astrosynth_storage';
  static const String _storeName = 'key_value_store';

  @override
  Future<void> init() async {
    if (_db != null) return;

    final db = await html.window.indexedDB!.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (e) {
        final db = e.target.result as html.Database;
        if (!db.objectStoreNames!.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );

    _db = db;
  }

  @override
  Future<void> setItem(String key, String value) async {
    await init();
    final transaction = _db!.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.put(value, key);
  }

  @override
  Future<String?> getItem(String key) async {
    await init();
    final transaction = _db!.transaction(_storeName, 'readonly');
    final store = transaction.objectStore(_storeName);
    final result = await store.getObject(key);
    return result?.toString();
  }

  @override
  Future<void> removeItem(String key) async {
    await init();
    final transaction = _db!.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.delete(key);
  }

  @override
  Future<void> clear() async {
    await init();
    final transaction = _db!.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);
    await store.clear();
  }

  @override
  Future<List<String>> getAllKeys() async {
    await init();
    final transaction = _db!.transaction(_storeName, 'readonly');
    final store = transaction.objectStore(_storeName);
    final keys = await store.getAllKeys(null);
    return keys.map((k) => k.toString()).toList();
  }
}
