import "package:freezed_annotation/freezed_annotation.dart";
part "user_config.freezed.dart";
part "user_config.g.dart";

@freezed
abstract class UserConfig with _$UserConfig {
  const factory UserConfig({required String? roomId, required String userId}) =
      _UserConfig;

  factory UserConfig.fromJson(Map<String, Object?> json) =>
      _$UserConfigFromJson(json);
}
