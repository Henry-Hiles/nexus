import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/ms_duration.dart";

part "set_state.freezed.dart";
part "set_state.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SetStateRequest({
  required final String roomId,
  required final String type,
  required final String stateKey,
  required final Content content,

  @JsonKey(name: "delay_ms", includeIfNull: false)
  @MSDuration()
  final Duration? delay,
}) with _$SetStateRequest {
  Map<String, Object?> toJson() => _$SetStateRequestToJson(this);

  factory SetStateRequest.fromJson(Map<String, Object?> json) =>
      _$SetStateRequestFromJson(json);
}
