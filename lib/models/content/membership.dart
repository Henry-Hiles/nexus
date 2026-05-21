import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/membership_status.dart";
part "membership.freezed.dart";
part "membership.g.dart";

@freezed
abstract class MembershipContent extends Content with _$MembershipContent {
  MembershipContent._();
  factory MembershipContent({
    @JsonKey(name: "displayname") required String? displayName,
    @JsonKey(name: "membership") required MembershipStatus status,
    Uri? avatarUrl,
    String? reason,
  }) = _MembershipContent;

  factory MembershipContent.fromJson(Map<String, Object?> json) =>
      _$MembershipContentFromJson(json);
}
