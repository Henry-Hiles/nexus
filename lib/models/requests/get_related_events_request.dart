import "package:freezed_annotation/freezed_annotation.dart";
part "get_related_events_request.freezed.dart";
part "get_related_events_request.g.dart";

@freezed
abstract class GetRelatedEventsRequest with _$GetRelatedEventsRequest {
  const factory GetRelatedEventsRequest({
    required String roomId,
    required String eventId,
    required String relationType,
  }) = _GetRelatedEventsRequest;

  factory GetRelatedEventsRequest.fromJson(Map<String, Object?> json) =>
      _$GetRelatedEventsRequestFromJson(json);
}
