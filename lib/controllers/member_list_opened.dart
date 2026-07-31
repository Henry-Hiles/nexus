import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/shared_prefs.dart";

class MemberListOpenedController extends Notifier<bool> {
  static const String key = "memberListOpened";

  @override
  bool build() =>
      ref.watch(SharedPrefsController.provider).requireValue.getBool(key) ??
      true;

  Future<void> set(bool value) async {
    final prefs = ref.watch(SharedPrefsController.provider).requireValue;
    state = value;

    prefs.setBool(key, value);
  }

  static final provider = NotifierProvider<MemberListOpenedController, bool>(
    MemberListOpenedController.new,
  );
}
