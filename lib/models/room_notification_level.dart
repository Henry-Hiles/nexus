import "package:material_ui/material_ui.dart";
import "package:nexus/models/push_rules.dart";

enum RoomNotificationLevel(
  final String title,
  final String description,
  final IconData icon,
) {
  global(
    "Default",
    "Follows your global notification rules.",
    Icons.notifications,
  ),
  allMessages(
    "All Messages",
    "Every message notifies you.",
    Icons.notifications_active,
  ),
  mentionsAndKeywords(
    "Mentions & Keywords",
    "Only messages that mention you or contain your keywords notify you.",
    Icons.alternate_email,
  ),
  mute("Mute", "Nothing in this room notifies you.", Icons.notifications_off);

  static RoomNotificationLevel of(PushRuleset ruleset, String roomId) =>
      switch ((ruleset.find(.override, roomId), ruleset.find(.room, roomId))) {
        (PushRule(enabled: true, actions: PushActions(notify: false)), _) =>
          .mute,
        (_, PushRule(enabled: true, actions: PushActions(notify: true))) =>
          .allMessages,
        (_, PushRule(enabled: true)) => .mentionsAndKeywords,
        _ => .global,
      };

  ({PushRuleKind kind, PushRule rule})? ruleFor(String roomId) =>
      switch (this) {
        .global => null,
        .allMessages => (
          kind: .room,
          rule: .new(ruleId: roomId, actions: .notifyWithSound),
        ),
        .mentionsAndKeywords => (kind: .room, rule: .new(ruleId: roomId)),
        .mute => (
          kind: .override,
          rule: .new(ruleId: roomId, conditions: .new([.inRoom(roomId)])),
        ),
      };
}
