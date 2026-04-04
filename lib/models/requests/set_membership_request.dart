import "package:freezed_annotation/freezed_annotation.dart";
part "set_membership_request.freezed.dart";
part "set_membership_request.g.dart";

@freezed
abstract class SetMembershipRequest with _$SetMembershipRequest {
  const factory SetMembershipRequest({
    required String userId,
    required String roomId,

    String? reason,
    @JsonKey(name: "action") required MembershipAction action,
    @Default(false) @JsonKey(name: "msc4293_redact_events") bool redact,
  }) = _SetMembershipRequest;

  factory SetMembershipRequest.fromJson(Map<String, Object?> json) =>
      _$SetMembershipRequestFromJson(json);
}

@JsonEnum()
enum MembershipAction { ban, kick, unban, invite }
