import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room_summary.dart";

part "room_directory.freezed.dart";
part "room_directory.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const RoomDirectory({
  @JsonKey(name: "chunk") final IList<RoomSummary> rooms = const .empty(),
  final String? nextBatch,
  final int? totalRoomCountEstimate,
}) with _$RoomDirectory {
  factory RoomDirectory.fromJson(Map<String, Object?> json) =>
      _$RoomDirectoryFromJson(json);
}
