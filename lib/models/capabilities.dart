import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "capabilities.freezed.dart";
part "capabilities.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Capabilities({
  @JsonKey(name: "org.matrix.msc4174.webpush") final WebPush? webpush,
  @JsonKey(name: "m.room_versions") final RoomVersions? roomVersions,
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

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RoomVersions({
  @JsonKey(name: "default") required final String defaultVersion,
  @JsonKey(fromJson: RoomVersionStability.mapFromJson)
  required final IMap<String, RoomVersionStability> available,
}) with _$RoomVersions {
  Map<String, Object?> toJson() => _$RoomVersionsToJson(this);

  factory RoomVersions.fromJson(Map<String, Object?> json) =>
      _$RoomVersionsFromJson(json);
}

enum RoomVersionStability {
  stable,
  unstable,
  unknown;

  static IMap<String, RoomVersionStability> mapFromJson(
    Map<String, dynamic> json,
  ) => IMap.fromJson(
    json,
    (version) => version as String,
    (stability) => values.asNameMap()[stability] ?? unknown,
  );
}
