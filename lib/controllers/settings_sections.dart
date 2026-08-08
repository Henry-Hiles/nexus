import "dart:io";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/models/account_data.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";

class SettingsSectionsController
    extends AsyncNotifier<IMap<String, IList<SettingsCategory>>> {
  @override
  Future<IMap<String, IList<SettingsCategory>>> build() async {
    final settings = await ref.watch(SettingsController.provider.future);
    final specVersionsResponse = await ref
        .watch(ClientController.provider.notifier)
        .getSpecVersions();

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
      if (ref.watch(ClientStateController.provider)?.isLoggedIn == true)
        "Account": .new([
          .new(title: "Profile", icon: Icons.person, settings: .new([])),
          .new(
            title: "Safety",
            icon: Icons.gpp_good,
            settings: .new([
              .new(
                title: "Invite Blocking",
                description:
                    "Block invites, either completely, or block only invites from users without shared private rooms (depends on server support).",
                builder: (title, description, icon) => Consumer(
                  builder: (context, ref, _) =>
                      DialogListTile<DefaultInviteAction>(
                        icon: Icon(icon),
                        title: title,
                        subtitle: Text(description),
                        initialValue: ref
                            .watch(AccountDataController.provider)
                            .invitePermissionConfig
                            .defaultAction,
                        options: specVersionsResponse.unstableFeatures.msc4494
                            ? DefaultInviteAction.values
                            : IList(
                                DefaultInviteAction.values,
                              ).remove(.denyPublic).toList(),
                        getName: (option) => switch (option) {
                          .allow => "Allow",
                          .deny => "Deny",
                          .denyPublic => "Deny public",
                        },
                        onChanged: (value) => ref
                            .watch(ClientController.provider.notifier)
                            .setAccountData(
                              .new(
                                type: AccountData.invitePermissionConfigKey,
                                content: InvitePermissionConfig(
                                  defaultAction: value,
                                ),
                              ),
                            )
                            .onError(showError),
                      ),
                ),
                icon: Icons.person_off,
              ),
            ]),
          ),
          .new(
            title: "Other",
            icon: Icons.key,
            settings: .new([
              .new(
                title: "Log Out",
                description:
                    "Log out of your account, returning you to the login page.",
                builder: (title, description, icon) => Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return M3EButton.icon(
                      onPressed: () async {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);

                        await WidgetsBinding.instance.endOfFrame;

                        await ref
                            .watch(ClientController.provider.notifier)
                            .logout();
                      },
                      label: Text(title),
                      icon: Icon(icon),
                      tooltip: description,
                      decoration: .styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                    );
                  },
                ),
                icon: Icons.logout,
              ),
            ]),
          ),
        ]),
    });
  }

  static final provider =
      AsyncNotifierProvider.autoDispose<
        SettingsSectionsController,
        IMap<String, IList<SettingsCategory>>
      >(SettingsSectionsController.new);
}
