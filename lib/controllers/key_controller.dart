import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs_controller.dart";

class KeyController extends Notifier<String?> {
  final String key;
  KeyController(this.key);

  static const String spaceKey = "space";
  static const String roomKey = "room";

  @override
  String? build() =>
      ref.watch(SharedPrefsController.provider).requireValue.getString(key);

  Future<void> set(String? id) async {
    final prefs = ref.watch(SharedPrefsController.provider).requireValue;
    state = id;

    if (id == null) {
      prefs.remove(key);
    } else {
      prefs.setString(key, id);
    }
  }

  static final provider =
      NotifierProvider.family<KeyController, String?, String>(
        KeyController.new,
      );
}
