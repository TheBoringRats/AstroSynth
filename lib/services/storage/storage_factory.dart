import 'storage_service.dart';
import 'storage_service_mobile.dart'
    if (dart.library.html) 'storage_service_web.dart';

/// Factory to create platform-specific storage service
StorageService createStorageService() {
  return StorageServiceMobile();
}
