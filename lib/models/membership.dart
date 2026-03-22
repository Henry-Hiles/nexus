import "package:freezed_annotation/freezed_annotation.dart";
part "membership.freezed.dart";
part "membership.g.dart";

@freezed
abstract class Membership with _$Membership {
  const factory Membership({
    required Uri? avatarUrl,
    required String displayName,
    required String userId,
  }) = _Membership;

  factory Membership.fromJson(Map<String, Object?> json) =>
      _$MembershipFromJson(json);
}
