import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "push_rules.freezed.dart";
part "push_rules.g.dart";

/// The content of the m.push_rules account data.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PushRules({final PushRuleset global = const .new()})
    with _$PushRules {
  Map<String, Object?> toJson() => _$PushRulesToJson(this);

  factory PushRules.fromJson(Map<String, Object?> json) =>
      _$PushRulesFromJson(json);
}

/// Push rules by kind, apart from sender rules, which Nexus doesn't use. The
/// first rule that matches decides what happens.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PushRuleset({
  final IList<PushRule> override = const .empty(),
  final IList<PushRule> content = const .empty(),
  final IList<PushRule> room = const .empty(),
  final IList<PushRule> underride = const .empty(),
}) with _$PushRuleset {
  IList<PushRule> ofKind(PushRuleKind kind) => switch (kind) {
    .override => override,
    .content => content,
    .room => room,
    .underride => underride,
  };

  PushRule? find(PushRuleKind kind, String ruleId) =>
      ofKind(kind).where((rule) => rule.ruleId == ruleId).firstOrNull;

  /// Mutes everything when enabled, as it matches every event.
  PushRule? get master => find(.override, ".m.rule.master");

  /// The content rules the user added, which match these words.
  IList<PushRule> get keywords =>
      content.where((rule) => !rule.isDefault).toIList();

  Map<String, Object?> toJson() => _$PushRulesetToJson(this);

  factory PushRuleset.fromJson(Map<String, Object?> json) =>
      _$PushRulesetFromJson(json);
}

enum PushRuleKind { override, content, room, underride }

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PushRule({
  required final String ruleId,
  final PushActions actions = const .new(),

  /// Whether the server made the rule, so it can't be deleted.
  @JsonKey(name: "default") final bool isDefault = false,
  final bool enabled = true,

  /// What content rules match in messages' bodies.
  final String? pattern,

  /// What override and underride rules match.
  final IList<PushCondition> conditions = const .empty(),
}) with _$PushRule {
  Map<String, Object?> toJson() => _$PushRuleToJson(this);

  factory PushRule.fromJson(Map<String, Object?> json) =>
      _$PushRuleFromJson(json);
}

/// Only the fields of event_match conditions are kept.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PushCondition({
  required final String kind,
  final String? key,
  final String? pattern,
}) with _$PushCondition {
  /// Matches events in the room with [roomId].
  factory PushCondition.inRoom(String roomId) =>
      .new(kind: "event_match", key: "room_id", pattern: roomId);

  Map<String, Object?> toJson() => _$PushConditionToJson(this);

  factory PushCondition.fromJson(Map<String, Object?> json) =>
      _$PushConditionFromJson(json);
}

/// What happens when a push rule matches. Actions Nexus doesn't support are
/// dropped, so they're replaced when these are changed.
@Freezed(toJson: false, fromJson: false)
class const PushActions({
  final bool notify = false,
  final bool highlight = false,
  final String? sound,
}) with _$PushActions {
  static const defaultSound = "default";
  static const notifyWithSound = PushActions(notify: true, sound: defaultSound);
  static const highlightWithSound = PushActions(
    notify: true,
    highlight: true,
    sound: defaultSound,
  );

  List<Object?> toJson() => [
    if (notify) "notify",
    if (highlight) {"set_tweak": "highlight"},
    if (sound != null) {"set_tweak": "sound", "value": sound},
  ];

  factory PushActions.fromJson(List<Object?> json) => json.fold(
    const .new(),
    (actions, action) => switch (action) {
      "notify" => actions.copyWith(notify: true),
      {"set_tweak": "highlight", "value": final bool highlight} =>
        actions.copyWith(highlight: highlight),
      {"set_tweak": "highlight"} => actions.copyWith(highlight: true),
      {"set_tweak": "sound", "value": final String sound} => actions.copyWith(
        sound: sound,
      ),
      _ => actions,
    },
  );
}
