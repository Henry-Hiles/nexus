import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class SecureStorageController extends Notifier<FlutterSecureStorage> {
  @override
  FlutterSecureStorage build() => FlutterSecureStorage();

  Future<String?> get(String key) => state.read(key: key);

  Future<void> set(String key, String value) =>
      state.write(key: key, value: value);

  Future<void> clear() => state.deleteAll();

  static final provider =
      NotifierProvider<SecureStorageController, FlutterSecureStorage>(
        SecureStorageController.new,
      );
}
