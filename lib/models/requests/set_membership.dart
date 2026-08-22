import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/membership_action.dart";

part "set_membership.freezed.dart";
part "set_membership.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SetMembershipRequest({
  required final String userId,
  required final String roomId,
  final String? reason,
  @JsonKey(name: "action") required final MembershipAction action,
  @JsonKey(name: "msc4293_redact_events") final bool redact = false,
}) with _$SetMembershipRequest {
  Map<String, Object?> toJson() => _$SetMembershipRequestToJson(this);

  factory SetMembershipRequest.fromJson(Map<String, Object?> json) =>
      _$SetMembershipRequestFromJson(json);
}
