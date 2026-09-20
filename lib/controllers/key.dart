import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class KeyController(final String key) extends AsyncNotifier<String?> {
  static const String spaceKey = "space";
  static const String roomKey = "room";
  static const String pushKeyKey = "pushKey";

  @override
  Future<String?> build() =>
      ref.watch(SharedPrefsController.provider).getString(key);

  Future<void> set(String? value) async {
    final prefs = ref.watch(SharedPrefsController.provider);
    state = .data(value);

    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  static final provider =
      AsyncNotifierProvider.family<KeyController, String?, String>(
        KeyController.new,
      );
}
