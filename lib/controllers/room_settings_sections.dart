import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/local_aliases.dart";
import "package:nexus/controllers/power_level.dart";
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
import "package:nexus/models/content/history_visibility.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/join_rule.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/settings/aliases_sheet.dart";
import "package:nexus/widgets/settings/allowed_rooms_sheet.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:nexus/widgets/settings/local_aliases_sheet.dart";
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
