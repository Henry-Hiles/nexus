import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "get_room_summary.freezed.dart";
part "get_room_summary.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetRoomSummary({
  required final String roomIdOrAlias,
  final IList<String> via = const IList.empty(),
}) with _$GetRoomSummary {
  Map<String, Object?> toJson() => _$GetRoomSummaryToJson(this);

  factory GetRoomSummary.fromJson(Map<String, Object?> json) =>
      _$GetRoomSummaryFromJson(json);
}
