import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class KeyController(final String key) extends Notifier<String?> {
  static const String spaceKey = "space";
  static const String roomKey = "room";

  @override
  String? build() =>
      ref.watch(SharedPrefsController.provider).requireValue.getString(key);

  Future<void> set(String? value) async {
    final prefs = ref.watch(SharedPrefsController.provider).requireValue;
    state = value;

    if (value == null) {
      prefs.remove(key);
    } else {
      prefs.setString(key, value);
    }
  }

  static final provider =
      NotifierProvider.family<KeyController, String?, String>(
        KeyController.new,
      );
}
