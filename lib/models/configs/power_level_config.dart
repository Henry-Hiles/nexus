import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/requests/membership_action.dart";
part "power_level_config.freezed.dart";
part "power_level_config.g.dart";

@freezed
abstract class PowerLevelConfig with _$PowerLevelConfig {
  const factory PowerLevelConfig({
    @Default(false) bool isStateEvent,
    required String eventType,
    MembershipAction? action,
    String? targetUser,
  }) = _PowerLevelConfig;

  factory PowerLevelConfig.fromJson(Map<String, Object?> json) =>
      _$PowerLevelConfigFromJson(json);
}
