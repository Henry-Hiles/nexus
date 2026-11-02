import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/shared_prefs.dart";
import "package:nexus/models/account.dart";

class KeyController(final String key) extends AsyncNotifier<String?> {
  static const String spaceKey = "space";
  static const String roomKey = "room";
  static const String pushKeyKey = "pushKey";
  static const String accountsKey = "accounts";
  static const String activeAccountKey = "activeAccount";

  static const ISet<String> _perAccountKeys = ISetConst({spaceKey, roomKey});

  String get _prefsKey {
    final account = ref.read(ActiveAccountController.provider);

    return _perAccountKeys.contains(key) && account != Account.legacyId
        ? "$account/$key"
        : key;
  }

  @override
  Future<String?> build() =>
      ref.watch(SharedPrefsController.provider).getString(_prefsKey);

  Future<void> set(String? value) async {
    final prefs = ref.read(SharedPrefsController.provider);
    state = .data(value);

    if (value == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, value);
    }
  }

  static final provider =
      AsyncNotifierProvider.family<KeyController, String?, String>(
        KeyController.new,
      );
}
