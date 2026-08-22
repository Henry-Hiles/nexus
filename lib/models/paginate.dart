import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "paginate.freezed.dart";
part "paginate.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Paginate({
  required final IList<Event> events,
  required final IList<Event> relatedEvents,
  required final bool hasMore,
}) with _$Paginate {
  Map<String, Object?> toJson() => _$PaginateToJson(this);

  factory Paginate.fromJson(Map<String, Object?> json) =>
      _$PaginateFromJson(json);
}
