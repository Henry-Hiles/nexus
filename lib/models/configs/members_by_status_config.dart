import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/membership_status.dart";
part "members_by_status_config.freezed.dart";
part "members_by_status_config.g.dart";

@freezed
abstract class MembersByStatusConfig with _$MembersByStatusConfig {
  const factory MembersByStatusConfig({
    required String roomId,
    required MembershipStatus status,
  }) = _MembersByStatusConfig;

  factory MembersByStatusConfig.fromJson(Map<String, Object?> json) =>
      _$MembersByStatusConfigFromJson(json);
}
