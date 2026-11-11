import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class BannedWarningDismissedController extends AsyncNotifier<bool> {
  static const String key = "bannedWarningDismissed";

  @override
  Future<bool> build() async =>
      await ref.watch(SharedPrefsController.provider).getBool(key) ?? false;

  Future<void> set(bool value) async {
    state = .data(value);
    await ref.read(SharedPrefsController.provider).setBool(key, value);
  }

  static final provider =
      AsyncNotifierProvider<BannedWarningDismissedController, bool>(
        BannedWarningDismissedController.new,
      );
}
