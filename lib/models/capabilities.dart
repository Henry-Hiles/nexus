import "package:freezed_annotation/freezed_annotation.dart";

part "capabilities.freezed.dart";
part "capabilities.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Capabilities({
  @JsonKey(name: "org.matrix.msc4174.webpush") final WebPush? webpush,
}) with _$Capabilities {
  Map<String, Object?> toJson() => _$CapabilitiesToJson(this);

  factory Capabilities.fromJson(Map<String, Object?> json) =>
      _$CapabilitiesFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const WebPush({required final bool enabled, final String? vapid})
    with _$WebPush {
  Map<String, Object?> toJson() => _$WebPushToJson(this);

  factory WebPush.fromJson(Map<String, Object?> json) =>
      _$WebPushFromJson(json);
}
