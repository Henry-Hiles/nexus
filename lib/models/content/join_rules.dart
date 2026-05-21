import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/join_rule.dart";
part "join_rules.freezed.dart";
part "join_rules.g.dart";

@freezed
abstract class JoinRulesContent extends Content with _$JoinRulesContent {
  JoinRulesContent._();
  factory JoinRulesContent({
    required JoinRule joinRule,
    @Default(IList.empty()) IList<AllowCondition> allow,
  }) = _JoinRulesContent;

  factory JoinRulesContent.fromJson(Map<String, Object?> json) =>
      _$JoinRulesContentFromJson(json);
}

@freezed
abstract class AllowCondition with _$AllowCondition {
  const factory AllowCondition({
    String? roomId,
    required AllowConditionType type,
  }) = _AllowCondition;

  factory AllowCondition.fromJson(Map<String, Object?> json) =>
      _$AllowConditionFromJson(json);
}

enum AllowConditionType {
  @JsonValue("m.room_membership")
  membership,
}
