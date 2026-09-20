import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class MemberListOpenedController extends AsyncNotifier<bool> {
  static const String key = "memberListOpened";

  @override
  Future<bool> build() async =>
      await ref.watch(SharedPrefsController.provider).getBool(key) ?? true;

  Future<void> set(bool value) async {
    state = .data(value);
    await ref.watch(SharedPrefsController.provider).setBool(key, value);
  }

  static final provider =
      AsyncNotifierProvider<MemberListOpenedController, bool>(
        MemberListOpenedController.new,
      );
}
