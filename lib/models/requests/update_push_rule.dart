import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/push_rules.dart";

part "update_push_rule.freezed.dart";
part "update_push_rule.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const UpdatePushRuleRequest({
  required final PushRuleKind kind,
  required final String ruleId,
  required final UpdatePushRuleAction action,

  /// The new rule, when putting it. Only its actions and pattern are used.
  final PushRule? newContent,

  /// The new actions, when putting only them.
  final PushActions? actions,
}) with _$UpdatePushRuleRequest {
  Map<String, Object?> toJson() => _$UpdatePushRuleRequestToJson(this);

  factory UpdatePushRuleRequest.fromJson(Map<String, Object?> json) =>
      _$UpdatePushRuleRequestFromJson(json);
}

@JsonEnum(fieldRename: .snake)
enum UpdatePushRuleAction { enable, disable, put, putActions, delete }
