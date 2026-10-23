import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/power_levels.dart";

enum PowerLevelPermission(
  final String title,
  final String description,
  final IconData icon,
) {
  usersDefault(
    "Default Power Level",
    "The power level of users who aren't given one.",
    Icons.person,
  ),
  eventsDefault(
    "Default for Events",
    "The power level needed to send events without their own.",
    Icons.more_horiz,
  ),
  stateDefault(
    "Default for State Events",
    "The power level needed to send state events without their own.",
    Icons.tune,
  ),
  invite(
    "Invite Users",
    "The power level needed to invite users.",
    Icons.person_add,
  ),
  kick(
    "Kick Users",
    "The power level needed to kick users.",
    Icons.sports_martial_arts,
  ),
  ban(
    "Ban Users",
    "The power level needed to ban and unban users.",
    Icons.gavel,
  ),
  redact(
    "Delete Others' Messages",
    "The power level needed to remove others' messages.",
    Icons.delete,
  ),
  notifyRoom(
    "Notify Everyone",
    "The power level needed to notify everyone in the room with @room.",
    Icons.campaign,
  );

  int levelIn(PowerLevelsContent content) => switch (this) {
    .usersDefault => content.usersDefault,
    .eventsDefault => content.eventsDefault,
    .stateDefault => content.stateDefault,
    .invite => content.invite,
    .kick => content.kick,
    .ban => content.ban,
    .redact => content.redact,
    .notifyRoom => content.notifications?.room ?? 50,
  };

  PowerLevelsContent withLevel(PowerLevelsContent content, int level) =>
      switch (this) {
        .usersDefault => content.copyWith(usersDefault: level),
        .eventsDefault => content.copyWith(eventsDefault: level),
        .stateDefault => content.copyWith(stateDefault: level),
        .invite => content.copyWith(invite: level),
        .kick => content.copyWith(kick: level),
        .ban => content.copyWith(ban: level),
        .redact => content.copyWith(redact: level),
        .notifyRoom => content.copyWith(
          notifications: (content.notifications ?? const Notifications())
              .copyWith(room: level),
        ),
      };
}

enum PowerLevelEvent(
  final EventType type,
  final String title,
  final String description,
  final IconData icon,
) {
  message(
    .message,
    "Send Messages",
    "The power level needed to send messages.",
    Icons.message,
  ),
  // Everything a client encrypts is sent as this, so its level is what limits
  // messages, stickers, and the like in encrypted rooms
  encrypted(
    .encrypted,
    "Send Encrypted Events",
    "The power level needed to send messages, stickers, files and anything else encrypted.",
    Icons.lock,
  ),
  sticker(
    .sticker,
    "Send Stickers",
    "The power level needed to send stickers.",
    Icons.sticky_note_2,
  ),
  reaction(
    .reaction,
    "Send Reactions",
    "The power level needed to react to messages.",
    Icons.add_reaction,
  ),
  pinnedEvents(
    .pinnedEvents,
    "Pin Messages",
    "The power level needed to pin messages.",
    Icons.push_pin,
  ),
  name(
    .name,
    "Change Name",
    "The power level needed to change the room's name.",
    Icons.title,
  ),
  topic(
    .topic,
    "Change Topic",
    "The power level needed to change the room's topic.",
    Icons.description,
  ),
  avatar(
    .avatar,
    "Change Avatar",
    "The power level needed to change the room's avatar.",
    Icons.image,
  ),
  canonicalAlias(
    .canonicalAlias,
    "Change Aliases",
    "The power level needed to change the room's canonical alias and published aliases.",
    Icons.numbers,
  ),
  powerLevels(
    .powerLevels,
    "Change Power Levels",
    "The power level needed to change power levels, including these.",
    Icons.admin_panel_settings,
  ),
  joinRules(
    .joinRules,
    "Change Join Rule",
    "The power level needed to change who can join the room.",
    Icons.login,
  ),
  historyVisibility(
    .historyVisibility,
    "Change History Visibility",
    "The power level needed to change who can read the room's history.",
    Icons.history,
  ),
  serverACL(
    .serverACL,
    "Change Server ACL",
    "The power level needed to change which servers can take part in the room.",
    Icons.dns,
  ),
  encryption(
    .encryption,
    "Enable Encryption",
    "The power level needed to enable encryption, which can't be turned off.",
    Icons.lock,
  ),
  tombstone(
    .tombstone,
    "Upgrade Room",
    "The power level needed to replace the room with an upgraded one.",
    Icons.upgrade,
  );

  static IList<PowerLevelEvent> shownIn({required bool encrypted}) => .new([
    if (encrypted) .encrypted else ...[.message, .sticker],
    .reaction,
  ]);

  static PowerLevelEvent? of(String type) =>
      values.where((event) => event.type.type == type).firstOrNull;
}

/// Power levels set together, like everything moderators need, to save
/// setting each one. Each can still be set on its own, by expanding it.
enum PowerLevelGroup(final String title, final IconData icon) {
  moderation("Moderation", Icons.shield),
  roomDetails("Room Details", Icons.edit),
  administration("Administration", Icons.admin_panel_settings);

  IList<PowerLevelPermission> get permissions => .new(switch (this) {
    .moderation => [.kick, .ban, .redact, .notifyRoom],
    .roomDetails || .administration => [],
  });

  IList<PowerLevelEvent> get events => .new(switch (this) {
    .moderation => [],
    .roomDetails => [.name, .topic, .avatar, .canonicalAlias, .pinnedEvents],
    .administration => [
      .powerLevels,
      .joinRules,
      .historyVisibility,
      .serverACL,
      .encryption,
      .tombstone,
    ],
  });

  String get description => [
    ...permissions.map((permission) => permission.title),
    ...events.map((event) => event.title),
  ].join(", ");

  int? levelIn(PowerLevelsContent content) {
    final levels = {
      ...permissions.map((permission) => permission.levelIn(content)),
      ...events.map(
        (event) => content.events[event.type.type] ?? content.stateDefault,
      ),
    };
    return levels.length == 1 ? levels.single : null;
  }

  int highestIn(PowerLevelsContent content) => [
    ...permissions.map((permission) => permission.levelIn(content)),
    ...events.map(
      (event) => content.events[event.type.type] ?? content.stateDefault,
    ),
  ].reduce(max);

  PowerLevelsContent withLevel(PowerLevelsContent content, int level) =>
      permissions
          .fold(
            content,
            (content, permission) => permission.withLevel(content, level),
          )
          .copyWith(
            events: content.events.addEntries(
              events.map((event) => MapEntry(event.type.type, level)),
            ),
          );
}
