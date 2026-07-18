import "dart:io";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/settings_controller.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";

class SettingsSectionsController
    extends AsyncNotifier<IMap<String, IList<SettingsCategory>>> {
  @override
  Future<IMap<String, IList<SettingsCategory>>> build() async {
    final settings = await ref.watch(SettingsController.provider.future);

    return .new({
      "General": .new([
        .new(
          title: "Appearance",
          icon: Icons.brush,
          settings: .new([
            .new(
              title: "Theme",
              description:
                  "Toggle between Light Mode, Dark Mode, and System themes.",
              icon: Icons.contrast,
              builder: (title, description, icon) => DialogListTile<ThemeMode>(
                icon: Icon(icon),
                title: title,
                subtitle: Text(description),
                initialValue: settings.theme,
                options: ThemeMode.values,
                getName: (option) => toBeginningOfSentenceCase(option.name),
                onChanged: (value) => ref
                    .watch(SettingsController.provider.notifier)
                    .set(settings.copyWith(theme: value))
                    .onError(showError),
              ),
            ),
            .new(
              title: "Use Dynamic Theme",
              icon: Icons.palette,
              description:
                  "Toggle on or off Dynamic Theme. Only available on Android, Linux, Windows, or MacOS.",
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.useDynamicTheming,
                onChanged:
                    (Platform.isAndroid ||
                        Platform.isLinux ||
                        Platform.isMacOS ||
                        Platform.isWindows)
                    ? (value) => ref
                          .watch(SettingsController.provider.notifier)
                          .set(settings.copyWith(useDynamicTheming: value))
                          .onError(showError)
                    : null,
              ),
            ),
          ]),
        ),
        .new(
          title: "Behavior",
          icon: Icons.psychology,
          settings: .new([
            .new(
              title: "Linux Mobile Mode",
              description:
                  "Enables some fixes for Linux mobile, e.g. disabling dragging appbar for moving window.",
              icon: Icons.construction,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.linuxMobileMode,
                onChanged: Platform.isLinux
                    ? (value) => ref
                          .watch(SettingsController.provider.notifier)
                          .set(settings.copyWith(linuxMobileMode: value))
                          .onError(showError)
                    : null,
              ),
            ),
          ]),
        ),
      ]),
    });
  }

  static final provider =
      AsyncNotifierProvider<
        SettingsSectionsController,
        IMap<String, IList<SettingsCategory>>
      >(SettingsSectionsController.new);
}
