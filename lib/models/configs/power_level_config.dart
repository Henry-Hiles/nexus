import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/requests/membership_action.dart";
part "power_level_config.freezed.dart";

@freezed
sealed class PowerLevelConfig with _$PowerLevelConfig {
  const factory PowerLevelConfig({
    required EventType eventType,
    required String roomId,
  }) = EventPowerLevelConfig;

  const factory PowerLevelConfig.membershipAction({
    required MembershipAction action,
    required String targetUser,
    required String roomId,
  }) = MembershipActionPowerLevelConfig;

  const factory PowerLevelConfig.state({
    required EventType eventType,
    required String roomId,
  }) = StatePowerLevelConfig;

  const factory PowerLevelConfig.redaction({
    required String targetUser,
    required String roomId,
  }) = RedactionPowerLevelConfig;
}
