import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:simple_secure_storage/simple_secure_storage.dart";

class SecureStorageController extends AsyncNotifier<void> {
  @override
  Future<void> build() => SimpleSecureStorage.initialize();

  Future<String?> get(String key) async {
    await future;
    return SimpleSecureStorage.read(key);
  }

  Future<void> set(String key, String value) async {
    await future;
    return SimpleSecureStorage.write(key, value);
  }

  Future<void> clear() async {
    await future;
    return SimpleSecureStorage.clear();
  }

  static final provider = AsyncNotifierProvider<SecureStorageController, void>(
    SecureStorageController.new,
  );
}
