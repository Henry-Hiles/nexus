import "package:freezed_annotation/freezed_annotation.dart";

part "get_event.freezed.dart";
part "get_event.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetEventRequest({
  required final String roomId,
  required final String eventId,
  final bool unredact = false,
}) with _$GetEventRequest {
  Map<String, Object?> toJson() => _$GetEventRequestToJson(this);

  factory GetEventRequest.fromJson(Map<String, Object?> json) =>
      _$GetEventRequestFromJson(json);
}
