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
import "package:nexus/helpers/extensions/join_rule_name.dart";
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
import "package:nexus/models/power_level_permission.dart";
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
    final (:state, :metadataTopic, :metadataAvatar) = ref.watch(
      RoomsController.provider.select((rooms) {
        final room = rooms[roomId];
        return (
          state: room?.state ?? const IMap.empty(),
          metadataTopic: room?.metadata?.topic,
          metadataAvatar: room?.metadata?.avatar,
        );
      }),
    );

    Content? contentOf(int rowId) =>
        ref.read(RoomsController.provider)[roomId]?.events[rowId]?.content;
    final client = ref.read(ClientController.provider.notifier);
    final roomsController = ref.read(RoomsController.provider.notifier);

    // The room's own state, rather than metadata like a name made up from
    // its members when it has none
    Content? stateContent(EventType type) => switch (state[type.type]?[""]) {
      final rowId? => contentOf(rowId),
      null => null,
    };
    final name = switch (stateContent(.name)) {
      NameContent(:final name) => name,
      _ => null,
    };
    final topic = switch (stateContent(.topic)) {
      TopicContent(:final topic) => topic,
      _ => metadataTopic,
    };
    final avatar = switch (stateContent(.avatar)) {
      AvatarContent(:final url) => url,
      _ => metadataAvatar,
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
        .addAll(state["m.space.parent"]?.keys ?? const [])
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
    final encrypted = stateContent(.encryption) is EncryptionContent;
    final shownEvents = PowerLevelEvent.shownIn(encrypted: encrypted);

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
    final listedEvents = shownEvents
        .addAll(PowerLevelGroup.values.expand((group) => group.events))
        .map((event) => event.type.type)
        .toISet();
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
        switch (state[EventType.membership.type]?[userId]) {
          final rowId? => switch (contentOf(rowId)) {
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

    Setting permissionSetting(PowerLevelPermission permission) =>
        powerLevelSetting(
          title: permission.title,
          description: permission.description,
          icon: permission.icon,
          value: permission.levelIn(powerLevels),
          update: (level) => permission.withLevel(powerLevels, level),
        );

    /// A setting for the level needed to send [event], which otherwise needs [fallback].
    Setting eventSetting(PowerLevelEvent event, {required int fallback}) =>
        powerLevelSetting(
          title: event.title,
          description: event.description,
          icon: event.icon,
          value: powerLevels.events[event.type.type] ?? fallback,
          update: (level) => powerLevels.copyWith(
            events: powerLevels.events.add(event.type.type, level),
          ),
        );

    Widget tileOf(Setting setting) =>
        setting.builder(setting.title, setting.description, setting.icon);

    /// A setting for all of [group]'s levels at once, which expands to set each.
    Setting groupSetting(PowerLevelGroup group) => .new(
      title: group.title,
      description: group.description,
      icon: group.icon,
      builder: (title, description, icon) => HookBuilder(
        builder: (context) {
          final expanded = useState(false);

          return Column(
            mainAxisSize: .min,
            children: [
              PowerLevelTile(
                leading: Icon(icon),
                title: title,
                description: description,
                value: group.levelIn(powerLevels),
                ownLevel: ownLevel,
                // Changing it would change levels above the user's own
                onChanged:
                    canSetPowerLevels &&
                        group.highestIn(powerLevels) <= ownLevel
                    ? (level) =>
                          setPowerLevels(group.withLevel(powerLevels, level))
                    : null,
                trailing: IconButton(
                  tooltip: expanded.value ? "Collapse" : "Set each",
                  icon: AnimatedRotation(
                    turns: expanded.value ? 0.5 : 0,
                    duration: Durations.medium2,
                    child: Icon(Icons.expand_more),
                  ),
                  onPressed: () => expanded.value = !expanded.value,
                ),
              ),
              AnimatedSize(
                duration: Durations.medium2,
                curve: Curves.easeInOut,
                alignment: .topCenter,
                child: expanded.value
                    ? Padding(
                        padding: .only(left: 16),
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            ...group.permissions
                                .map(permissionSetting)
                                .map(tileOf),
                            ...group.events
                                .map(
                                  (event) => eventSetting(
                                    event,
                                    fallback: powerLevels.stateDefault,
                                  ),
                                )
                                .map(tileOf),
                          ],
                        ),
                      )
                    : const SizedBox(width: .infinity),
              ),
            ],
          );
        },
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
                getName: (rule) => rule.displayName,
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
                      .unknown => "Unknown",
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
            permissionSetting(.usersDefault),
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
              "Groups",
              "Power levels set together, which can each be set on their own.",
              Icons.workspaces,
            ),
            ...PowerLevelGroup.values.map(groupSetting),
            header(
              "Regular Events",
              "Power levels needed to send messages and other timeline events.",
              Icons.chat,
            ),
            ...shownEvents
                .where((event) => event != .pinnedEvents)
                .map(
                  (event) =>
                      eventSetting(event, fallback: powerLevels.eventsDefault),
                ),
            permissionSetting(.eventsDefault),
            header(
              "State Events",
              "Power levels needed to change the room's state.",
              Icons.settings,
            ),
            permissionSetting(.invite),
            permissionSetting(.stateDefault),
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
