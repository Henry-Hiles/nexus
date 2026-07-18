import "dart:io";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:xdg_directories/xdg_directories.dart";

class SettingsFileController extends AsyncNotifier<File> {
  @override
  Future<File> build() async {
    final directory = await switch (Platform.isLinux) {
      true => Directory(
        join(configHome.absolute.path, "nexus"),
      ).create(recursive: true),
      false => getApplicationSupportDirectory(),
    };

    return File(join(directory.absolute.path, "config.json"));
  }

  static final provider = AsyncNotifierProvider<SettingsFileController, File>(
    SettingsFileController.new,
  );
}
