/// Abstract storage interface for cross-platform data persistence
abstract class StorageService {
  Future<void> init();
  Future<void> setItem(String key, String value);
  Future<String?> getItem(String key);
  Future<void> removeItem(String key);
  Future<void> clear();
  Future<List<String>> getAllKeys();
}
