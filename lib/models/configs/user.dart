import "package:freezed_annotation/freezed_annotation.dart";

part "user.freezed.dart";
part "user.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const UserConfig({final String? roomId, required final String userId})
    with _$UserConfig {
  Map<String, Object?> toJson() => _$UserConfigToJson(this);

  factory UserConfig.fromJson(Map<String, Object?> json) =>
      _$UserConfigFromJson(json);
}
