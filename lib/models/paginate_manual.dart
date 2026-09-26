import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "paginate_manual.freezed.dart";
part "paginate_manual.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PaginateManual({
  required final IList<Event> events,
  final IList<Event> relatedEvents = const IList.empty(),
  required final String? nextBatch,
}) with _$PaginateManual {
  Map<String, Object?> toJson() => _$PaginateManualToJson(this);

  factory PaginateManual.fromJson(Map<String, Object?> json) =>
      _$PaginateManualFromJson(json);
}
