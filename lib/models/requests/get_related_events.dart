import "package:freezed_annotation/freezed_annotation.dart";

part "get_related_events.freezed.dart";
part "get_related_events.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetRelatedEventsRequest({
  required final String roomId,
  required final String eventId,
  required final String relationType,
}) with _$GetRelatedEventsRequest {
  Map<String, Object?> toJson() => _$GetRelatedEventsRequestToJson(this);

  factory GetRelatedEventsRequest.fromJson(Map<String, Object?> json) =>
      _$GetRelatedEventsRequestFromJson(json);
}
