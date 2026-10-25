import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/membership_status.dart";
part "membership.freezed.dart";
part "membership.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const MembershipContent({
  @JsonKey(name: "displayname", fromJson: MembershipContent.displaynameFromJson)
  required final String? displayName,
  @JsonKey(name: "membership", unknownEnumValue: MembershipStatus.unknown)
  required final MembershipStatus status,
  final Uri? avatarUrl,
  final String? reason,
  final bool isDirect = false,
}) extends Content with _$MembershipContent {
  static String? displaynameFromJson(String? displayName) =>
      displayName?.isEmpty == true ? null : displayName;

  @override
  Map<String, Object?> toJson() => _$MembershipContentToJson(this);

  factory MembershipContent.fromJson(Map<String, Object?> json) =>
      _$MembershipContentFromJson(json);
}
