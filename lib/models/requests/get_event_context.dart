import "package:freezed_annotation/freezed_annotation.dart";

part "get_event_context.freezed.dart";
part "get_event_context.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetEventContextRequest({
  required final String roomId,
  required final String eventId,
  final int limit = 20,
}) with _$GetEventContextRequest {
  Map<String, Object?> toJson() => _$GetEventContextRequestToJson(this);

  factory GetEventContextRequest.fromJson(Map<String, Object?> json) =>
      _$GetEventContextRequestFromJson(json);
}
