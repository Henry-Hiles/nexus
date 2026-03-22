import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "member_config.freezed.dart";
part "member_config.g.dart";

@freezed
abstract class MemberConfig with _$MemberConfig {
  const factory MemberConfig({required Room room, required String userId}) =
      _MemberConfig;

  factory MemberConfig.fromJson(Map<String, Object?> json) =>
      _$MemberConfigFromJson(json);
}
