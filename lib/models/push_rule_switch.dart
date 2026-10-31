import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/push_rules.dart";

enum PushRuleSection(
  final String title,
  final String description,
  final IconData icon,
) {
  messages("Messages", "Which messages notify you.", Icons.chat),
  otherEvents("Other Events", "Events other than messages.", Icons.more_horiz),
}

/// Default push rules turned on or off together, as some match the same events
/// in different ways, like encrypted ones, which the server can't read.
enum PushRuleSwitch(
  final PushRuleSection section,
  final String title,
  final String description,
  final IconData icon,

  /// What the rules do when on.
  final PushActions actions,

  /// Whether turning it off disables the rules, so the next rule that matches
  /// decides, rather than not notifying.
  final bool disableWhenOff,
) {
  mentions(
    .messages,
    "Mentions",
    "Messages that mention you, or contain your name.",
    Icons.alternate_email,
    .highlightWithSound,
    true,
  ),
  roomMentions(
    .messages,
    "Room Mentions",
    "Messages that notify everyone in the room with @room.",
    Icons.campaign,
    .highlightWithSound,
    true,
  ),
  directMessages(
    .messages,
    "Direct Messages",
    "Messages in rooms with just you and one other person.",
    Icons.person,
    .notifyWithSound,
    false,
  ),
  groupMessages(
    .messages,
    "Group Messages",
    "Messages in rooms with more people, rather than only mentions and keywords.",
    Icons.group,
    .notifyWithSound,
    false,
  ),
  invites(
    .otherEvents,
    "Invites",
    "Invites for you to join rooms.",
    Icons.mail,
    .notifyWithSound,
    false,
  ),
  calls(
    .otherEvents,
    "Calls",
    "Incoming calls.",
    Icons.call,
    .new(notify: true, sound: "ring"),
    false,
  ),
  tombstones(
    .otherEvents,
    "Room Tombstones",
    "Rooms being upgraded or locked.",
    Icons.lock,
    .notifyWithSound,
    false,
  );

  IList<({PushRuleKind kind, String ruleId})> get rules => .new(switch (this) {
    .mentions => [
      (kind: .override, ruleId: ".m.rule.is_user_mention"),
      (kind: .override, ruleId: ".m.rule.contains_display_name"),
      (kind: .content, ruleId: ".m.rule.contains_user_name"),
    ],
    .roomMentions => [
      (kind: .override, ruleId: ".m.rule.is_room_mention"),
      (kind: .override, ruleId: ".m.rule.roomnotif"),
    ],
    .directMessages => [
      (kind: .underride, ruleId: ".m.rule.room_one_to_one"),
      (kind: .underride, ruleId: ".m.rule.encrypted_room_one_to_one"),
    ],
    .groupMessages => [
      (kind: .underride, ruleId: ".m.rule.message"),
      (kind: .underride, ruleId: ".m.rule.encrypted"),
    ],
    .invites => [(kind: .override, ruleId: ".m.rule.invite_for_me")],
    .calls => [(kind: .underride, ruleId: ".m.rule.call")],
    .tombstones => [(kind: .override, ruleId: ".m.rule.tombstone")],
  });

  /// The rules in [ruleset], as servers may not have them all.
  IList<({PushRuleKind kind, PushRule rule})> rulesIn(PushRuleset ruleset) =>
      rules
          .map(
            (rule) => switch (ruleset.find(rule.kind, rule.ruleId)) {
              final found? => (kind: rule.kind, rule: found),
              null => null,
            },
          )
          .nonNulls
          .toIList();

  /// Whether the rules in [ruleset] are on or off, or null if they're set up
  /// some other way.
  bool? valueIn(PushRuleset ruleset) => switch (rulesIn(ruleset)
      .map((entry) => entry.rule)) {
    final rules
        when rules.every((rule) => rule.enabled && rule.actions == actions) =>
      true,
    final rules
        when rules.every((rule) => !rule.enabled || !rule.actions.notify) =>
      false,
    _ => null,
  };

  /// The rules in [ruleset], turned on or off.
  IList<({PushRuleKind kind, PushRule rule})> changesIn(
    PushRuleset ruleset,
    bool value,
  ) => rulesIn(ruleset)
      .map(
        (entry) => (
          kind: entry.kind,
          rule: value
              ? entry.rule.copyWith(enabled: true, actions: actions)
              : disableWhenOff
              ? entry.rule.copyWith(enabled: false)
              : entry.rule.copyWith(enabled: true, actions: const .new()),
        ),
      )
      .toIList();
}
