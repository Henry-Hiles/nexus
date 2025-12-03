import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

class SharedPrefsController extends AsyncNotifier<SharedPreferences> {
  @override
  Future<SharedPreferences> build() => SharedPreferences.getInstance();

  static final provider =
      AsyncNotifierProvider<SharedPrefsController, SharedPreferences>(
        SharedPrefsController.new,
      );
}
