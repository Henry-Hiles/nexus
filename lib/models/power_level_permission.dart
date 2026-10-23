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
  );

  static IList<PowerLevelEvent> shownIn({required bool encrypted}) => .new([
    if (encrypted) .encrypted else ...[.message, .sticker],
    .reaction,
    .pinnedEvents,
  ]);

  static PowerLevelEvent? of(String type) =>
      values.where((event) => event.type.type == type).firstOrNull;
}
