import "package:freezed_annotation/freezed_annotation.dart";

part "gomuks_config.freezed.dart";
part "gomuks_config.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GomuksConfig({
  final MatrixConfig? matrix,
  final PushConfig? push,
  final MediaConfig? media,
}) with _$GomuksConfig {
  Map<String, Object?> toJson() => _$GomuksConfigToJson(this);

  factory GomuksConfig.fromJson(Map<String, Object?> json) =>
      _$GomuksConfigFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const MatrixConfig({
  @JsonKey(name: "disable_http2") final bool disableHttp2 = false,
  @JsonKey(name: "set_presence") final String? setPresence,
  @JsonKey(name: "initial_device_display_name")
  required final String initialDeviceDisplayName,
}) with _$MatrixConfig {
  Map<String, Object?> toJson() => _$MatrixConfigToJson(this);

  factory MatrixConfig.fromJson(Map<String, Object?> json) =>
      _$MatrixConfigFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PushConfig({
  @JsonKey(name: "fcm_gateway") required final String fcmGateway,
  @JsonKey(name: "vapid_private_key") required final String vapidPrivateKey,
  @JsonKey(name: "vapid_public_key") required final String vapidPublicKey,
}) with _$PushConfig {
  Map<String, Object?> toJson() => _$PushConfigToJson(this);

  factory PushConfig.fromJson(Map<String, Object?> json) =>
      _$PushConfigFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const MediaConfig({
  @JsonKey(name: "thumbnail_size") required final int thumbnailSize,
}) with _$MediaConfig {
  Map<String, Object?> toJson() => _$MediaConfigToJson(this);

  factory MediaConfig.fromJson(Map<String, Object?> json) =>
      _$MediaConfigFromJson(json);
}
