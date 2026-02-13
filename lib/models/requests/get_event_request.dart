import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "get_event_request.freezed.dart";
part "get_event_request.g.dart";

@freezed
abstract class GetEventRequest with _$GetEventRequest {
  const factory GetEventRequest({
    required Room room,
    required String eventId,
    @Default(false) bool unredact,
  }) = _GetEventRequest;

  factory GetEventRequest.fromJson(Map<String, Object?> json) =>
      _$GetEventRequestFromJson(json);
}
