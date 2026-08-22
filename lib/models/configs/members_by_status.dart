import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/membership_status.dart";

part "members_by_status.freezed.dart";
part "members_by_status.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const MembersByStatusConfig({
  required final String roomId,
  required final MembershipStatus status,
}) with _$MembersByStatusConfig {
  Map<String, Object?> toJson() => _$MembersByStatusConfigToJson(this);

  factory MembersByStatusConfig.fromJson(Map<String, Object?> json) =>
      _$MembersByStatusConfigFromJson(json);
}
