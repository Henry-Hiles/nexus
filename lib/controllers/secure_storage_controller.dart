import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:simple_secure_storage/simple_secure_storage.dart";

class SecureStorageController extends AsyncNotifier<void> {
  @override
  Future<void> build() => SimpleSecureStorage.initialize();

  static final provider = AsyncNotifierProvider<SecureStorageController, void>(
    SecureStorageController.new,
  );
}
