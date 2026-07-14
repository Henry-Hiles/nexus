import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/ms_duration.dart";
part "set_state_request.freezed.dart";
part "set_state_request.g.dart";

@freezed
abstract class SetStateRequest with _$SetStateRequest {
  const factory SetStateRequest({
    required String roomId,
    required String type,
    required String stateKey,
    required Content content,

    @JsonKey(name: "delay_ms", includeIfNull: false)
    @MSDuration()
    @Default(null)
    Duration? delay,
  }) = _SetStateRequest;

  factory SetStateRequest.fromJson(Map<String, Object?> json) =>
      _$SetStateRequestFromJson(json);
}
