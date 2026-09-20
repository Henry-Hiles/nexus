import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

class SharedPrefsController extends Notifier<SharedPreferencesAsync> {
  @override
  SharedPreferencesAsync build() => SharedPreferencesAsync();

  static final provider =
      NotifierProvider<SharedPrefsController, SharedPreferencesAsync>(
        SharedPrefsController.new,
      );
}
