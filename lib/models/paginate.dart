import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
part "paginate.freezed.dart";
part "paginate.g.dart";

@freezed
abstract class Paginate with _$Paginate {
  const factory Paginate({
    required IList<Event> events,
    required IList<Event> relatedEvents,
    required bool hasMore,
  }) = _Paginate;

  factory Paginate.fromJson(Map<String, Object?> json) =>
      _$PaginateFromJson(json);
}
