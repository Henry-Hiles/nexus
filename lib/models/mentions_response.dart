import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "mentions_response.freezed.dart";
part "mentions_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const MentionsResponse({
  required final IList<Event> events,
  final IList<Event> relatedEvents = const .empty(),
}) with _$MentionsResponse {
  factory MentionsResponse.fromJson(Map<String, Object?> json) =>
      _$MentionsResponseFromJson(json);
}
