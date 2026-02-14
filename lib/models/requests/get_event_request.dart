import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "get_event_request.freezed.dart";
part "get_event_request.g.dart";

@Freezed(toJson: false)
abstract class GetEventRequest with _$GetEventRequest {
  const GetEventRequest._();
  const factory GetEventRequest({
    required Room room,
    required String eventId,
    @Default(false) bool unredact,
  }) = _GetEventRequest;

  Map<String, dynamic> toJson() => {
    "room_id": room.metadata?.id,
    "event_id": eventId,
    "unredact": unredact,
  };

  factory GetEventRequest.fromJson(Map<String, Object?> json) =>
      _$GetEventRequestFromJson(json);
}
