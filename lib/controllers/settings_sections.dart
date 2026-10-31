import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:intl/intl.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:multi_state_switch/multi_state_switch.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/enabled_image_packs.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/notification.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/unified_push.dart";
import "package:nexus/controllers/spec_versions.dart";
import "package:nexus/controllers/unified_push_allowed.dart";
import "package:nexus/controllers/unified_push_distributors.dart";
import "package:nexus/helpers/extensions/distributor_name.dart";
import "package:nexus/helpers/extensions/room_image_packs.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/models/account_data.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/models/name_color.dart";
import "package:nexus/models/push_rule_switch.dart";
import "package:nexus/models/room_order.dart";
import "package:nexus/models/setting.dart";
import "package:nexus/models/settings.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/models/show_and_send.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/image_pack_avatar.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:nexus/widgets/settings/enable_image_packs_sheet.dart";
import "package:nexus/widgets/settings/keyword_field.dart";
import "package:nexus/widgets/user_bottom_sheet.dart";
import "package:nexus/widgets/reset_encryption_sheet.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";

class SettingsSectionsController
    extends AsyncNotifier<IMap<String, IList<SettingsCategory>>> {
  @override
  Future<IMap<String, IList<SettingsCategory>>> build() async {
    final settings = await ref.watch(SettingsController.provider.future);

    // Loads the enabled packs' state, so they can be shown
    ref.watch(EnabledImagePacksController.provider);
    final enabledPacks = ref.watch(
      AccountDataController.provider.select((data) => data.enabledImagePacks),
    );
    final enabledPackInfo = ref.watch(
      RoomsController.provider.select(
        (rooms) => enabledPacks.rooms.entries.expand((entry) {
          final room = rooms[entry.key];
          final packs = room?.imagePacks(entry.key) ?? const .empty();

          return entry.value.keys.map(
            (stateKey) => (
              roomId: entry.key,
              stateKey: stateKey,
              roomName: room?.metadata?.name ?? entry.key,
              pack: packs[stateKey],
            ),
          );
        }).toIList(),
      ),
    );

    Future<void> setEnabledPacks(ImagePackRooms packs) => ref
        .read(AccountDataController.provider.notifier)
        .setEnabledImagePacks(packs);

    /// A tile for a [ShowAndSend] setting, saving the settings from [update].
    Widget showAndSendTile(
      String title,
      String description,
      IconData icon, {
      required ShowAndSend value,
      required Settings Function(ShowAndSend value) update,
    }) => DialogListTile<ShowAndSend>(
      icon: Icon(icon),
      title: title,
      subtitle: Text(description),
      value: value,
      options: ShowAndSend.values,
      getName: (option) => switch (option) {
        .showAndSend => "Show and send",
        .show => "Only show",
        .neither => "Neither",
      },
      onChanged: (value) => ref
          .read(SettingsController.provider.notifier)
          .set(update(value))
          .onError(showError),
    );

    final pushRules = ref.watch(
      AccountDataController.provider.select((data) => data.pushRules.global),
    );
    final accountData = ref.read(AccountDataController.provider.notifier);

    Setting header(String title, String description, IconData icon) => .new(
      title: title,
      description: description,
      icon: icon,
      builder: (title, _, _) => Padding(
        padding: .symmetric(horizontal: 16),
        child: DividerText(title),
      ),
    );

    /// A switch for push rules, which is disabled while [onChanged] saves. A
    /// null [value] is shown in the middle, for rules set up some other way.
    Setting pushSwitchSetting({
      required String title,
      required String description,
      required IconData icon,
      required bool? value,
      required Future<void> Function(bool value) onChanged,
    }) => .new(
      title: title,
      description: description,
      icon: icon,
      builder: (title, description, icon) => HookBuilder(
        builder: (context) {
          final saving = Saving.use();
          final position = switch (value) {
            false => 0,
            null => 1,
            true => 2,
          };
          void change(bool value) =>
              saving.run(() => onChanged(value)).onError(showError);

          return ListTile(
            enabled: !saving.active,
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(description),
            trailing: MultiStateSwitch(
              states: 3,
              // As wide as a regular switch, which has 2 states 20 apart
              stepWidth: 10,
              value: position,
              semanticFormatterCallback: (position) =>
                  ["Off", "Custom", "On"][position],
              onChanged: saving.active
                  ? null
                  : (newPosition) => change(newPosition > position),
            ),
            // Tapping turns it off only when it's fully on
            onTap: () => change(value != true),
          );
        },
      ),
    );

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
                value: settings.theme,
                options: ThemeMode.values,
                getName: (option) => toBeginningOfSentenceCase(option.name),
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(theme: value))
                    .onError(showError),
              ),
            ),
            .new(
              title: "Use Dynamic Theme",
              icon: Icons.palette,
              description: "Toggle on or off Dynamic Theme. Only available on Android, Linux, Windows, or MacOS.",
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
                          .read(SettingsController.provider.notifier)
                          .set(settings.copyWith(useDynamicTheming: value))
                          .onError(showError)
                    : null,
              ),
            ),
            .new(
              title: "Name Colors",
              description: "Color names by power level, so moderators and admins stand out, or by user, so everyone has their own.",
              icon: Icons.format_color_text,
              builder: (title, description, icon) => DialogListTile<NameColor>(
                icon: Icon(icon),
                title: title,
                subtitle: Text(description),
                value: settings.nameColor,
                options: NameColor.values,
                getName: (option) => switch (option) {
                  .powerLevel => "By power level",
                  .user => "By user",
                },
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(nameColor: value))
                    .onError(showError),
              ),
            ),
          ]),
        ),
        .new(
          title: "Behavior",
          icon: Icons.psychology,
          settings: .new([
            .new(
              title: "All Rooms In Home",
              description: "Show all rooms in home, instead of just ones that aren't in spaces",
              icon: Icons.home,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.showAllInHome,
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(showAllInHome: value))
                    .onError(showError),
              ),
            ),
            .new(
              title: "Room Ordering",
              description: "Sort rooms by recent activity, optionally showing mentioned and unread rooms first.",
              icon: Icons.sort,
              builder: (title, description, icon) => DialogListTile<RoomOrder>(
                icon: Icon(icon),
                title: title,
                subtitle: Text(description),
                value: settings.roomOrder,
                options: RoomOrder.values,
                getName: (option) => switch (option) {
                  .unreadFirst => "Mentioned, then unread",
                  .recentActivity => "Recent activity only",
                },
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(roomOrder: value))
                    .onError(showError),
              ),
            ),
            .new(
              title: "Swipe To Reply",
              description: "Swipe a message to the right to reply to it.",
              icon: Icons.swipe_right,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.swipeToReply,
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(swipeToReply: value))
                    .onError(showError),
              ),
            ),
            if (!Platform.isAndroid && !Platform.isIOS)
              .new(
                title: "Show Minimize Button",
                description:
                    "Enable this to add a minimize button to the appbar",
                icon: Icons.minimize,
                builder: (title, description, icon) => SwitchListTile(
                  title: Text(title),
                  subtitle: Text(description),
                  secondary: Icon(icon),
                  value: settings.showMinimizeButton,
                  onChanged: (value) => ref
                      .read(SettingsController.provider.notifier)
                      .set(settings.copyWith(showMinimizeButton: value))
                      .onError(showError),
                ),
              ),
            .new(
              title: "Linux Mobile Mode",
              description: "Enables some fixes for Linux mobile, e.g. disabling dragging appbar for moving window, and swiping drawers open.",
              icon: Icons.construction,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.linuxMobileMode,
                onChanged: Platform.isLinux
                    ? (value) => ref
                          .read(SettingsController.provider.notifier)
                          .set(settings.copyWith(linuxMobileMode: value))
                          .onError(showError)
                    : null,
              ),
            ),
            .new(
              title: "Hide Membership Events",
              description: "Hides membership events (invites, joins, leaves & bans) from appearing in conversations. Knocks are still shown.",
              icon: Icons.person_off,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.hideMembershipEvents,
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(hideMembershipEvents: value))
                    .onError(showError),
              ),
            ),
            .new(
              title: "Hide Server ACL Events",
              description: "Hides server ACL (server ban list) changes from appearing in conversations.",
              icon: Icons.dns,
              builder: (title, description, icon) => SwitchListTile(
                title: Text(title),
                subtitle: Text(description),
                secondary: Icon(icon),
                value: settings.hideServerAclEvents,
                onChanged: (value) => ref
                    .read(SettingsController.provider.notifier)
                    .set(settings.copyWith(hideServerAclEvents: value))
                    .onError(showError),
              ),
            ),
          ]),
        ),
        .new(
          title: "Privacy",
          icon: Icons.privacy_tip,
          settings: .new([
            .new(
              title: "Typing Indicators",
              description: "Show when others are typing, and let others see when you're typing.",
              icon: Icons.keyboard,
              builder: (title, description, icon) => showAndSendTile(
                title,
                description,
                icon,
                value: settings.typingIndicators,
                update: (value) => settings.copyWith(typingIndicators: value),
              ),
            ),
            .new(
              title: "Read Receipts",
              description: "Show how far others have read, and let others see what you've read. When not sent, read receipts are still sent privately, so your other devices know what you've read.",
              icon: Icons.done_all,
              builder: (title, description, icon) => showAndSendTile(
                title,
                description,
                icon,
                value: settings.readReceipts,
                update: (value) => settings.copyWith(readReceipts: value),
              ),
            ),
          ]),
        ),
      ]),
      if (ref.watch(ClientStateController.provider) case ClientState(
        isLoggedIn: true,
        :final userId?,
      ))
        "Account": .new([
          .new(
            title: "Profile",
            icon: Icons.person,
            settings: .new([
              .new(
                title: "Profile",
                description: "Your avatar, display name, pronouns, and timezone, as others see them.",
                icon: Icons.person,
                builder: (title, description, icon) => Center(
                  child: ConstrainedBox(
                    constraints: .new(maxWidth: 500),
                    child: UserBottomSheet(userId, editable: true),
                  ),
                ),
              ),
            ]),
          ),
          .new(
            title: "Image Packs",
            icon: Icons.emoji_emotions,
            settings: .new([
              ...enabledPackInfo.map(
                (info) => Setting(
                  title:
                      info.pack?.name ??
                      ImagePack.fallbackName(info.roomName, info.stateKey),
                  description: info.roomName,
                  icon: Icons.emoji_emotions,
                  builder: (title, description, _) => HookBuilder(
                    key: ValueKey((info.roomId, info.stateKey)),
                    builder: (context) {
                      final saving = Saving.use();

                      return ListTile(
                        enabled: !saving.active,
                        leading: ImagePackAvatar(info.pack?.icon),
                        title: Text(title),
                        subtitle: Text(description),
                        trailing: IconButton(
                          tooltip: "Remove pack",
                          icon: Icon(Icons.delete),
                          onPressed: saving.active
                              ? null
                              : () => saving.run(
                                  () => setEnabledPacks(
                                    ref
                                        .read(AccountDataController.provider)
                                        .enabledImagePacks
                                        .withPack(
                                          info.roomId,
                                          info.stateKey,
                                          enabled: false,
                                        ),
                                  ).onError(showError),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              .new(
                title: "Add Packs",
                description:
                    "Use image packs from any of your rooms in every room.",
                icon: Icons.add,
                builder: (title, description, icon) => HookBuilder(
                  builder: (context) {
                    final saving = Saving.use();

                    return ListTile(
                      enabled: !saving.active,
                      leading: Icon(icon),
                      title: Text(title),
                      subtitle: Text(description),
                      onTap: () => context.showAdaptiveSheet(
                        (_) => EnableImagePacksSheet(
                          enabled: enabledPacks,
                          onSave: (packs) => saving.run(
                            () => setEnabledPacks(packs).onError(showError),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
          .new(
            title: "Notifications",
            icon: Icons.notifications,
            settings: .new([
              .new(
                title: "Push Notifications",
                description: "Enable push notifications using Web Push, and choose which UnifiedPush distributor to use.",
                builder: (title, description, icon) => HookConsumer(
                  builder: (context, ref, _) {
                    final loading = useState(false);
                    final pusherRegistered = ref.watch(
                      UnifiedPushController.provider,
                    );
                    final unifiedPushAllowed = ref.watch(
                      UnifiedPushAllowedController.provider,
                    );
                    final distributors = ref.watch(
                      UnifiedPushDistributorsController.provider,
                    );
                    final current = pusherRegistered.value;

                    return DialogListTile<String?>(
                      title: title,
                      subtitle: Text(
                        unifiedPushAllowed.maybeWhen(
                              data: (data) => data,
                              orElse: () => null,
                            ) ??
                            description,
                      ),
                      icon: Icon(icon),
                      value: current,
                      options: [
                        null,
                        ...?distributors.value,
                        if (current != null &&
                            distributors.value?.contains(current) != true)
                          current,
                      ],
                      getName: (option) =>
                          option == null ? "Off" : option.distributorName,
                      onChanged: loading.value
                          ? null
                          : unifiedPushAllowed.maybeWhen(
                              data: (data) => data == null,
                              orElse: () => false,
                            )
                          ? pusherRegistered.maybeWhen(
                              data: (_) => (value) async {
                                if (value == current) return;
                                try {
                                  loading.value = true;
                                  if (value != null) {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    if (!await ref
                                        .read(
                                          NotificationController
                                              .provider
                                              .notifier,
                                        )
                                        .requestPermissions()) {
                                      messenger.showSnackBar(
                                        .new(
                                          content: Text(
                                            "Notifications are disabled. Enable them for Nexus in your system settings.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    await ref
                                        .read(
                                          UnifiedPushController
                                              .provider
                                              .notifier,
                                        )
                                        .register(value);
                                  } else {
                                    await ref
                                        .read(
                                          UnifiedPushController
                                              .provider
                                              .notifier,
                                        )
                                        .deregister();
                                  }
                                } catch (error, stackTrace) {
                                  showError(error, stackTrace);
                                } finally {
                                  loading.value = false;
                                }
                              },
                              orElse: () => null,
                            )
                          : null,
                    );
                  },
                ),
                icon: Icons.notification_add,
              ),
              if (pushRules.master case final master?)
                pushSwitchSetting(
                  title: "Mute All",
                  description: "Don't notify for anything, without changing your other rules.",
                  icon: Icons.notifications_off,
                  value: master.enabled,
                  onChanged: (mute) => accountData.savePushRule(
                    .override,
                    master.copyWith(enabled: mute),
                  ),
                ),
              ...PushRuleSection.values.expand(
                (section) => [
                  header(section.title, section.description, section.icon),
                  ...PushRuleSwitch.values
                      .where(
                        (option) =>
                            option.section == section &&
                            option.rulesIn(pushRules).isNotEmpty,
                      )
                      .map(
                        (option) => pushSwitchSetting(
                          title: option.title,
                          description: option.description,
                          icon: option.icon,
                          value: option.valueIn(pushRules),
                          onChanged: (value) => Future.wait(
                            option
                                .changesIn(pushRules, value)
                                .map(
                                  (change) => accountData.savePushRule(
                                    change.kind,
                                    change.rule,
                                  ),
                                ),
                          ),
                        ),
                      ),
                ],
              ),
              header(
                "Keywords",
                "Messages containing these words, which notify with a highlight and sound.",
                Icons.text_fields,
              ),
              ...pushRules.keywords.map(
                (rule) => Setting(
                  title: rule.pattern ?? rule.ruleId,
                  description: "Messages containing this keyword.",
                  icon: Icons.text_fields,
                  builder: (title, description, icon) => HookBuilder(
                    key: ValueKey(rule.ruleId),
                    builder: (context) {
                      final saving = Saving.use();
                      final custom =
                          !rule.enabled || rule.actions != .highlightWithSound;

                      return ListTile(
                        enabled: !saving.active,
                        leading: Icon(icon),
                        title: Text(title),
                        trailing: IconButton(
                          tooltip: custom
                              ? "Set up differently by another client. Press to reset to Nexus defaults."
                              : "Remove keyword",
                          icon: Icon(custom ? Icons.warning : Icons.delete),
                          onPressed: saving.active
                              ? null
                              : () => saving
                                    .run(
                                      () => custom
                                          ? accountData.savePushRule(
                                              .content,
                                              rule.copyWith(
                                                enabled: true,
                                                actions: .highlightWithSound,
                                              ),
                                            )
                                          : accountData.deletePushRule(
                                              .content,
                                              rule.ruleId,
                                            ),
                                    )
                                    .onError(showError),
                        ),
                      );
                    },
                  ),
                ),
              ),
              .new(
                title: "Add Keyword",
                description: "Notify for messages containing a word.",
                icon: Icons.add,
                builder: (_, _, _) => KeywordField(),
              ),
            ]),
          ),
          .new(
            title: "Safety",
            icon: Icons.gpp_good,
            settings: .new([
              .new(
                title: "Invite Blocking",
                description: "Block invites, either completely, or block only invites from users without shared private rooms (depends on server support).",
                builder: (title, description, icon) => Consumer(
                  builder: (context, ref, _) {
                    final specVersionsResponse = ref.watch(
                      SpecVersionsController.provider,
                    );
                    return DialogListTile<DefaultInviteAction>(
                      icon: Icon(icon),
                      title: title,
                      subtitle: Text(description),
                      value: ref
                          .watch(AccountDataController.provider)
                          .invitePermissionConfig
                          .defaultAction,
                      options:
                          specVersionsResponse.maybeWhen(
                            data: (data) => data.unstableFeatures.msc4494,
                            orElse: () => true,
                          )
                          ? DefaultInviteAction.values
                          : IList(DefaultInviteAction.values)
                                .remove(.denyPublic)
                                .toList(),
                      getName: (option) => switch (option) {
                        .allow => "Allow",
                        .deny => "Deny",
                        .denyPublic => "Deny public",
                      },
                      onChanged: specVersionsResponse.maybeWhen(
                        data: (_) =>
                            (value) => ref
                                .read(ClientController.provider.notifier)
                                .setAccountData(
                                  .new(
                                    type: AccountData.invitePermissionConfigKey,
                                    content: InvitePermissionConfig(
                                      defaultAction: value,
                                    ),
                                  ),
                                )
                                .onError(showError),
                        orElse: () => null,
                      ),
                    );
                  },
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
                title: "Reset Encryption Identity",
                description: "Replace your encryption identity and recovery key with new ones, if you've lost your recovery key or your encryption is broken.",
                builder: (title, description, icon) => Builder(
                  builder: (context) => M3EButton.icon(
                    onPressed: () => context.showAdaptiveSheet(
                      (_) => const ResetEncryptionSheet(),
                    ),
                    label: Text(title),
                    icon: Icon(icon),
                    tooltip: description,
                  ),
                ),
                icon: Icons.key_off,
              ),
              .new(
                title: "Log Out",
                description:
                    "Log out of your account, returning you to the login page.",
                builder: (title, description, icon) => Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return M3EButton.icon(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);

                        final route = ModalRoute.of(context)!;
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        await route.completed;

                        await container
                            .read(UnifiedPushController.provider.notifier)
                            .deregister()
                            .onError(showError);
                        container.invalidate(InitCompleteController.provider);
                        await container
                            .read(ClientController.provider.notifier)
                            .logout()
                            .onError(showError);
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
