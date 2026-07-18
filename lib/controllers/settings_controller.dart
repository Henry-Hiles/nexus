import "dart:convert";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/settings_file_controller.dart";
import "package:nexus/models/settings.dart";

class SettingsController extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    final file = await ref.watch(SettingsFileController.provider.future);

    try {
      return Settings.fromJson(json.decode(await file.readAsString()));
    } catch (_) {
      return Settings();
    }
  }

  Future<void> set(Settings settings) async {
    state = AsyncData(settings);
    final file = await ref.watch(SettingsFileController.provider.future);
    await file.writeAsString(json.encode(settings.toJson()));
  }

  static final provider = AsyncNotifierProvider<SettingsController, Settings>(
    SettingsController.new,
  );
}
