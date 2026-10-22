import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/local_aliases.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/power_levels_saving.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/file_dialog_helper.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/canonical_alias.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/encryption.dart";
import "package:nexus/models/content/history_visibility.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/join_rule.dart";
import "package:nexus/models/setting.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/settings/add_users_power_level_sheet.dart";
import "package:nexus/widgets/settings/aliases_sheet.dart";
import "package:nexus/widgets/settings/allowed_rooms_sheet.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:nexus/widgets/settings/local_aliases_sheet.dart";
import "package:nexus/widgets/settings/power_level_entry_sheet.dart";
import "package:nexus/widgets/settings/power_level_tile.dart";
import "package:nexus/widgets/settings/text_setting_tile.dart";

class RoomSettingsSectionsController(final String roomId)
    extends AsyncNotifier<IMap<String, IList<SettingsCategory>>> {
  @override
  Future<IMap<String, IList<SettingsCategory>>> build() async {
    final room = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]),
    );
    final client = ref.read(ClientController.provider.notifier);
    final roomsController = ref.read(RoomsController.provider.notifier);

    // The room's own state, rather than metadata like a name made up from
    // its members when it has none
    Content? stateContent(EventType type) =>
        switch (room?.state[type.type]?[""]) {
          final rowId? => room?.events[rowId]?.content,
          null => null,
        };
    final name = switch (stateContent(.name)) {
      NameContent(:final name) => name,
      _ => null,
    };
    final topic = switch (stateContent(.topic)) {
      TopicContent(:final topic) => topic,
      _ => room?.metadata?.topic,
    };
    final avatar = switch (stateContent(.avatar)) {
      AvatarContent(:final url) => url,
      _ => room?.metadata?.avatar,
    };

    bool canSet(EventType type) => ref.watch(
      PowerLevelController.provider(.state(eventType: type, roomId: roomId)),
    );

    final canSetAvatar = canSet(.avatar);
    final canSetName = canSet(.name);
    final canSetTopic = canSet(.topic);
    final canSetJoinRules = canSet(.joinRules);
    final canSetHistoryVisibility = canSet(.historyVisibility);
    final canSetAliases = canSet(.canonicalAlias);
    final canSetPowerLevels =
        canSet(.powerLevels) &&
        !ref.watch(PowerLevelsSavingController.provider(roomId));

    final joinRules = switch (stateContent(.joinRules)) {
      final JoinRulesContent content => content,
      _ => JoinRulesContent(joinRule: .invite),
    };
    final historyVisibility = switch (stateContent(.historyVisibility)) {
      HistoryVisibilityContent(:final historyVisibility) => historyVisibility,
      _ => HistoryVisibility.shared,
    };
    final canonicalAlias = switch (stateContent(.canonicalAlias)) {
      final CanonicalAliasContent content => content,
      _ => CanonicalAliasContent(),
    };
    final published = canonicalAlias.altAliases.addAll([?canonicalAlias.alias]);
    final localAliases =
        ref.watch(LocalAliasesController.provider(roomId)).value ??
        const IList<String>.empty();

    final knownAliases = localAliases.addAll(canonicalAlias.altAliases).addAll([
      ?canonicalAlias.alias,
    ]).toISet();

    final roomVersion = switch (stateContent(.create)) {
      CreateContent(:final roomVersion) => int.tryParse(roomVersion),
      _ => null,
    };
    bool versionAtLeast(int version) =>
        roomVersion == null || roomVersion >= version;
    final joinRuleOptions = [
      JoinRule.public,
      JoinRule.invite,
      if (versionAtLeast(7)) JoinRule.knock,
      if (versionAtLeast(8)) JoinRule.restricted,
      if (versionAtLeast(10)) JoinRule.knockRestricted,
    ];
    bool isRestricted(JoinRule rule) =>
        rule == .restricted || rule == .knockRestricted;

    final parentSpaces = ref
        .watch(
          SpaceEdgesController.provider.select(
            (edges) => edges.entries
                .where(
                  (entry) => entry.value.any((edge) => edge.childId == roomId),
                )
                .map((entry) => entry.key)
                .toIList(),
          ),
        )
        .addAll(room?.state["m.space.parent"]?.keys ?? const [])
        .toISet();
    final allowedRooms = joinRules.allow
        .map((condition) => condition.roomId)
        .nonNulls
        .toISet();

    final roomPowerLevels = ref.watch(
      RoomPowerLevelsController.provider(roomId),
    );
    final powerLevels = roomPowerLevels.content;
    final userId = ref.watch(
      ClientStateController.provider.select((state) => state?.userId),
    );
    final ownLevel = userId == null ? 0.0 : roomPowerLevels.levelOf(userId);
    // Encrypted rooms send messages as m.room.encrypted, so that's what limits them
    final messageType = stateContent(.encryption) is EncryptionContent
        ? EventType.encrypted
        : EventType.message;

    Future<void> setState(EventType type, Content content) async {
      final eventId = await client.setState(
        .new(roomId: roomId, type: type.type, stateKey: "", content: content),
      );
      if (eventId case final eventId?) {
        await roomsController.awaitState(roomId, type.type, eventId);
      }
    }

    Future<void> setAliases(
      String? canonical,
      ISet<String> alternatives,
    ) async {
      final stale = (await Future.wait(
        alternatives.addAll([?canonical]).map((alias) async {
          try {
            return await client.resolveAlias(alias) == roomId ? null : alias;
          } catch (_) {
            return null;
          }
        }),
      )).nonNulls.toISet();
      bool kept(String alias) => !stale.contains(alias);

      await setState(
        .canonicalAlias,
        CanonicalAliasContent(
          alias: canonical != null && kept(canonical) ? canonical : null,
          altAliases: alternatives.where(kept).toISet(),
        ),
      );
    }

    Future<void> setAllowedRooms(ISet<String> roomIds) => setState(
      .joinRules,
      joinRules.copyWith(
        allow: roomIds
            .map((roomId) => AllowCondition(roomId: roomId, type: .membership))
            .toISet(),
      ),
    );

    Setting header(String title, String description, IconData icon) => .new(
      title: title,
      description: description,
      icon: icon,
      builder: (title, _, _) => Padding(
        padding: .symmetric(horizontal: 16),
        child: DividerText(title),
      ),
    );

    Future<void> setPowerLevels(PowerLevelsContent content) => ref
        .read(PowerLevelsSavingController.provider(roomId).notifier)
        .run(() => setState(.powerLevels, content).onError(showError));

    // Event types with their own level that don't have a setting of their own
    final listedEvents = [
      messageType,
      EventType.sticker,
      EventType.reaction,
      EventType.pinnedEvents,
    ].map((type) => type.type).toISet();
    final otherEvents = powerLevels.events.entries
        .where((entry) => !listedEvents.contains(entry.key))
        .toIList()
        .sort((a, b) => a.key.compareTo(b.key));

    // Users with their own level, the highest first
    final users = powerLevels.users.entries.toIList().sort(
      (a, b) => switch (b.value.compareTo(a.value)) {
        0 => a.key.compareTo(b.key),
        final order => order,
      },
    );
    MembershipContent? memberOf(String userId) =>
        switch (room?.state[EventType.membership.type]?[userId]) {
          final rowId? => switch (room?.events[rowId]?.content) {
            final MembershipContent content => content,
            _ => null,
          },
          null => null,
        };

    /// A tile opening a [sheet] to add entries, like event types or users, with their own power level.
    Setting addSetting({
      required String title,
      required String description,
      required Widget Function(void Function(PowerLevelsContent content) save)
      sheet,
    }) => .new(
      title: title,
      description: description,
      icon: Icons.add,
      builder: (title, description, icon) => Builder(
        builder: (context) => ListTile(
          enabled: canSetPowerLevels,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(description),
          onTap: () => context.showAdaptiveSheet((_) => sheet(setPowerLevels)),
        ),
      ),
    );

    Setting powerLevelSetting({
      required String title,
      required String description,
      required IconData icon,
      required int value,
      required PowerLevelsContent Function(int level) update,
    }) => .new(
      title: title,
      description: description,
      icon: icon,
      builder: (title, description, icon) => PowerLevelTile(
        leading: Icon(icon),
        title: title,
        description: description,
        value: value,
        ownLevel: ownLevel,
        onChanged: canSetPowerLevels
            ? (level) => setPowerLevels(update(level))
            : null,
      ),
    );

    /// A setting for the level needed to send [type], which otherwise needs [fallback].
    Setting eventSetting(
      EventType type, {
      required String title,
      required String description,
      required IconData icon,
      required int fallback,
    }) => powerLevelSetting(
      title: title,
      description: description,
      icon: icon,
      value: powerLevels.events[type.type] ?? fallback,
      update: (level) => powerLevels.copyWith(
        events: powerLevels.events.add(type.type, level),
      ),
    );

    return .new({
      "Room": .new([
        .new(
          title: "General",
          icon: Icons.tune,
          settings: .new([
            .new(
              title: "Avatar",
              description: "The image shown for the room.",
              icon: Icons.image,
              builder: (title, description, icon) => HookBuilder(
                builder: (context) {
                  final saving = Saving.use();
                  Future<void> save(Future<void> Function() action) =>
                      saving.run(() => action().onError(showError));

                  return ListTile(
                    enabled: canSetAvatar && !saving.active,
                    leading: Icon(icon),
                    title: Text(title),
                    subtitle: Text(description),
                    trailing: Row(
                      mainAxisSize: .min,
                      spacing: 8,
                      children: [
                        AvatarOrHash(
                          avatar,
                          name ?? "Unnamed Room",
                          dimension: 40,
                          fallback: Icon(Icons.numbers),
                        ),
                        if (avatar != null && canSetAvatar)
                          IconButton(
                            tooltip: "Remove avatar",
                            icon: Icon(Icons.delete),
                            onPressed: saving.active
                                ? null
                                : () => save(
                                    () => setState(.avatar, const .new()),
                                  ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      final file = await ProviderScope.containerOf(context)
                          .read(FileDialogHelper.provider)
                          .pickFile(images: true);
                      if (file == null || !context.mounted) return;

                      await save(() async {
                        final content = await client.uploadMedia(
                          .new(path: file.path, encrypt: false),
                        );
                        if (content case ImageMessageContent(
                          :final url,
                          :final info,
                        )) {
                          await setState(
                            .avatar,
                            AvatarContent(url: url, info: info),
                          );
                        } else {
                          throw Exception("The file isn't an image");
                        }
                      });
                    },
                  );
                },
              ),
            ),
            .new(
              title: "Room Name",
              description: "The name shown for the room.",
              icon: Icons.title,
              builder: (title, description, icon) => TextSettingTile(
                icon: Icon(icon),
                title: title,
                description: description,
                value: name,
                onChanged: canSetName
                    ? (value) => setState(
                        .name,
                        NameContent(name: value),
                      ).onError(showError)
                    : null,
              ),
            ),
            .new(
              title: "Topic",
              description: "A short description of the room.",
              icon: Icons.info,
              builder: (title, description, icon) => TextSettingTile(
                icon: Icon(icon),
                title: title,
                description: description,
                value: topic,
                multiline: true,
                onChanged: canSetTopic
                    ? (value) => setState(
                        .topic,
                        TopicContent(
                          topic: value,
                          content: .new(
                            representations: .new([.new(body: value)]),
                          ),
                        ),
                      ).onError(showError)
                    : null,
              ),
            ),
          ]),
        ),
        .new(
          title: "Access",
          icon: Icons.key,
          settings: .new([
            .new(
              title: "Join Rule",
              description: "Who can join the room.",
              icon: Icons.login,
              builder: (title, description, icon) => DialogListTile<JoinRule>(
                icon: Icon(icon),
                title: title,
                subtitle: Text(description),
                value: joinRules.joinRule,
                options: joinRuleOptions,
                getName: (rule) => switch (rule) {
                  .public => "Public",
                  .invite => "Invite only",
                  .knock => "Knock",
                  .restricted => "Restricted",
                  .knockRestricted => "Restricted or knock",
                  .private => "Private",
                },
                onChanged: canSetJoinRules
                    ? (rule) => setState(
                        .joinRules,
                        JoinRulesContent(
                          joinRule: rule,
                          allow: isRestricted(rule) && joinRules.allow.isEmpty
                              ? .new(
                                  parentSpaces.map(
                                    (roomId) =>
                                        .new(roomId: roomId, type: .membership),
                                  ),
                                )
                              : joinRules.allow,
                        ),
                      ).onError(showError)
                    : null,
              ),
            ),
            if (isRestricted(joinRules.joinRule))
              .new(
                title: "Allowed Rooms",
                description:
                    "Members of these rooms can join without an invite.",
                icon: Icons.meeting_room,
                builder: (title, description, icon) => HookConsumer(
                  builder: (context, ref, _) {
                    final saving = Saving.use();
                    final names = ref.watch(
                      RoomsController.provider.select(
                        (rooms) => allowedRooms
                            .map(
                              (roomId) =>
                                  rooms[roomId]?.metadata?.name ?? roomId,
                            )
                            .toIList(),
                      ),
                    );

                    return ListTile(
                      enabled: canSetJoinRules && !saving.active,
                      leading: Icon(icon),
                      title: Text(title),
                      subtitle: Text(
                        names.isEmpty
                            ? "None, so only invited users can join"
                            : names.join(", "),
                        maxLines: 2,
                        overflow: .ellipsis,
                      ),
                      onTap: () => context.showAdaptiveSheet(
                        (_) => AllowedRoomsSheet(
                          roomId: roomId,
                          allowed: allowedRooms,
                          parentSpaces: parentSpaces,
                          onSave: (allowed) => saving.run(
                            () => setAllowedRooms(allowed).onError(showError),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            .new(
              title: "Aliases",
              description:
                  "The addresses the room advertises, and its main one.",
              icon: Icons.alternate_email,
              builder: (title, description, icon) => HookBuilder(
                builder: (context) {
                  final saving = Saving.use();

                  return ListTile(
                    enabled: canSetAliases && !saving.active,
                    leading: Icon(icon),
                    title: Text(title),
                    subtitle: Text(
                      switch ((
                        canonicalAlias.alias,
                        canonicalAlias.altAliases.length,
                      )) {
                        (null, 0) => description,
                        (final alias?, 0) => alias,
                        (final alias?, 1) =>
                          "$alias and ${canonicalAlias.altAliases.first}",
                        (final alias?, final others) =>
                          "$alias and $others more",
                        (null, _) => canonicalAlias.altAliases.join(", "),
                      },
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                    onTap: () => context.showAdaptiveSheet(
                      (_) => AliasesSheet(
                        aliases: knownAliases,
                        canonical: canonicalAlias.alias,
                        alternatives: canonicalAlias.altAliases,
                        onSave: (canonical, alternatives) => saving.run(
                          () => setAliases(
                            canonical,
                            alternatives,
                          ).onError(showError),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            .new(
              title: "Local Aliases",
              description: "Addresses for the room on your server.",
              icon: Icons.dns,
              builder: (title, description, icon) => Builder(
                builder: (context) => ListTile(
                  leading: Icon(icon),
                  title: Text(title),
                  subtitle: Text(
                    localAliases.isEmpty
                        ? description
                        : localAliases.join(", "),
                    maxLines: 2,
                    overflow: .ellipsis,
                  ),
                  onTap: () => context.showAdaptiveSheet(
                    (_) => LocalAliasesSheet(
                      roomId,
                      onRemoved: canSetAliases
                          ? (alias) async {
                              if (published.contains(alias)) {
                                await setAliases(
                                  canonicalAlias.alias,
                                  canonicalAlias.altAliases,
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            .new(
              title: "History Visibility",
              description:
                  "Which messages from before joining members can read.",
              icon: Icons.history,
              builder: (title, description, icon) =>
                  DialogListTile<HistoryVisibility>(
                    icon: Icon(icon),
                    title: title,
                    subtitle: Text(description),
                    value: historyVisibility,
                    options: [.shared, .invited, .joined],
                    getName: (visibility) => switch (visibility) {
                      .shared => "All events",
                      .invited => "After invite",
                      .joined => "After join",
                      .worldReadable => "Anyone",
                    },
                    onChanged: canSetHistoryVisibility
                        ? (visibility) => setState(
                            .historyVisibility,
                            HistoryVisibilityContent(
                              historyVisibility: visibility,
                            ),
                          ).onError(showError)
                        : null,
                  ),
            ),
          ]),
        ),
        .new(
          title: "Permissions",
          icon: Icons.admin_panel_settings,
          settings: .new([
            powerLevelSetting(
              title: "Default Power Level",
              description: "The power level of users who aren't given one.",
              icon: Icons.person,
              value: powerLevels.usersDefault,
              update: (level) => powerLevels.copyWith(usersDefault: level),
            ),
            header("Users", "Power levels of specific users.", Icons.group),
            ...users.map((entry) {
              final member = memberOf(entry.key);
              // Others can only be changed if they're below you, but your own level can be lowered
              final canChange =
                  canSetPowerLevels &&
                  (entry.key == userId || entry.value < ownLevel);

              return Setting(
                title: member?.displayName ?? entry.key,
                description: entry.key,
                icon: Icons.person,
                builder: (title, description, _) => PowerLevelTile(
                  leading: AvatarOrHash(
                    member?.avatarUrl,
                    title,
                    dimension: 40,
                  ),
                  title: title,
                  description: description,
                  value: entry.value,
                  ownLevel: ownLevel,
                  onChanged: canChange
                      ? (level) => setPowerLevels(
                          powerLevels.copyWith(
                            users: powerLevels.users.add(entry.key, level),
                          ),
                        )
                      : null,
                  onRemoved: canChange
                      ? () => setPowerLevels(
                          powerLevels.copyWith(
                            users: powerLevels.users.remove(entry.key),
                          ),
                        )
                      : null,
                  removeConfirmation: entry.key == userId
                      ? "Remove your own power level? You'll have the default of ${powerLevels.usersDefault}, and won't be able to raise it again yourself."
                      : "Remove $title's power level? They'll have the default of ${powerLevels.usersDefault}.",
                ),
              );
            }),
            addSetting(
              title: "Add Users",
              description: "Give users their own power level.",
              sheet: (save) => AddUsersPowerLevelSheet(
                roomId: roomId,
                existing: powerLevels.users.keys.toISet().union(
                  roomPowerLevels.creators,
                ),
                ownLevel: ownLevel,
                onSave: (users, level) => save(
                  powerLevels.copyWith(
                    users: powerLevels.users.addEntries(
                      users.map((user) => MapEntry(user, level)),
                    ),
                  ),
                ),
              ),
            ),
            header(
              "Regular Events",
              "Power levels needed to send messages and other timeline events.",
              Icons.chat,
            ),
            eventSetting(
              messageType,
              title: "Send Messages",
              description: "The power level needed to send messages.",
              icon: Icons.message,
              fallback: powerLevels.eventsDefault,
            ),
            eventSetting(
              .sticker,
              title: "Send Stickers",
              description: "The power level needed to send stickers.",
              icon: Icons.sticky_note_2,
              fallback: powerLevels.eventsDefault,
            ),
            eventSetting(
              .reaction,
              title: "Send Reactions",
              description: "The power level needed to react to messages.",
              icon: Icons.add_reaction,
              fallback: powerLevels.eventsDefault,
            ),
            powerLevelSetting(
              title: "Default for Events",
              description:
                  "The power level needed to send events without their own.",
              icon: Icons.more_horiz,
              value: powerLevels.eventsDefault,
              update: (level) => powerLevels.copyWith(eventsDefault: level),
            ),
            header(
              "State Events",
              "Power levels needed to manage members and change the room's state.",
              Icons.settings,
            ),
            eventSetting(
              .pinnedEvents,
              title: "Pin Messages",
              description: "The power level needed to pin messages.",
              icon: Icons.push_pin,
              fallback: powerLevels.stateDefault,
            ),
            powerLevelSetting(
              title: "Invite Users",
              description: "The power level needed to invite users.",
              icon: Icons.person_add,
              value: powerLevels.invite,
              update: (level) => powerLevels.copyWith(invite: level),
            ),
            powerLevelSetting(
              title: "Kick Users",
              description: "The power level needed to kick users.",
              icon: Icons.sports_martial_arts,
              value: powerLevels.kick,
              update: (level) => powerLevels.copyWith(kick: level),
            ),
            powerLevelSetting(
              title: "Ban Users",
              description: "The power level needed to ban and unban users.",
              icon: Icons.gavel,
              value: powerLevels.ban,
              update: (level) => powerLevels.copyWith(ban: level),
            ),
            powerLevelSetting(
              title: "Delete Others' Messages",
              description: "The power level needed to remove others' messages.",
              icon: Icons.delete,
              value: powerLevels.redact,
              update: (level) => powerLevels.copyWith(redact: level),
            ),
            powerLevelSetting(
              title: "Default for State Events",
              description: "The power level needed to send state events without their own.",
              icon: Icons.tune,
              value: powerLevels.stateDefault,
              update: (level) => powerLevels.copyWith(stateDefault: level),
            ),
            header(
              "Other Events",
              "Power levels for specific event types.",
              Icons.code,
            ),
            ...otherEvents.map(
              (entry) => Setting(
                title: entry.key,
                description: "The power level needed to send this event.",
                icon: Icons.code,
                builder: (title, _, icon) => PowerLevelTile(
                  leading: Icon(icon),
                  title: title,
                  description: null,
                  value: entry.value,
                  ownLevel: ownLevel,
                  onChanged: canSetPowerLevels
                      ? (level) => setPowerLevels(
                          powerLevels.copyWith(
                            events: powerLevels.events.add(entry.key, level),
                          ),
                        )
                      : null,
                  onRemoved: canSetPowerLevels
                      ? () => setPowerLevels(
                          powerLevels.copyWith(
                            events: powerLevels.events.remove(entry.key),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            addSetting(
              title: "Add Event",
              description: "Give an event type its own power level.",
              sheet: (save) => PowerLevelEntrySheet(
                title: "Add Event",
                keyLabel: "Event type",
                keyHint: "m.room.name",
                ownLevel: ownLevel,
                onSave: (type, level) => save(
                  powerLevels.copyWith(
                    events: powerLevels.events.add(type, level),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    });
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        RoomSettingsSectionsController,
        IMap<String, IList<SettingsCategory>>,
        String
      >(RoomSettingsSectionsController.new);
}
