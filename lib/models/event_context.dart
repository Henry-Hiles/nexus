import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "event_context.freezed.dart";
part "event_context.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const EventContext({
  required final Event event,
  required final IList<Event> before,
  required final IList<Event> after,
  required final String start,
  required final String end,
  final IList<Event> relatedEvents = const IList.empty(),
}) with _$EventContext {
  Map<String, Object?> toJson() => _$EventContextToJson(this);

  factory EventContext.fromJson(Map<String, Object?> json) =>
      _$EventContextFromJson(json);
}
