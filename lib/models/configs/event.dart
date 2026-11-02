import "package:freezed_annotation/freezed_annotation.dart";

part "event.freezed.dart";
part "event.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const EventConfig({
  required final String roomId,
  required final int eventRowId,
}) with _$EventConfig {
  Map<String, Object?> toJson() => _$EventConfigToJson(this);

  factory EventConfig.fromJson(Map<String, Object?> json) =>
      _$EventConfigFromJson(json);
}
