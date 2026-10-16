import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room_summary.dart";

part "space_hierarchy.freezed.dart";
part "space_hierarchy.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const SpaceHierarchy({
  final IList<SpaceHierarchyRoom> rooms = const .empty(),
  final String? nextBatch,
}) with _$SpaceHierarchy {
  factory SpaceHierarchy.fromJson(Map<String, Object?> json) =>
      _$SpaceHierarchyFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const SpaceHierarchyRoom({
  @JsonKey(readValue: SpaceHierarchyRoom.readEntry)
  required final RoomSummary summary,
  @JsonKey(name: "children_state")
  final IList<SpaceHierarchyChild> children = const .empty(),
}) with _$SpaceHierarchyRoom {
  static Object? readEntry(Map json, String _) => json;

  factory SpaceHierarchyRoom.fromJson(Map<String, Object?> json) =>
      _$SpaceHierarchyRoomFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const SpaceHierarchyChild({
  @JsonKey(name: "state_key") required final String roomId,
  @JsonKey(readValue: SpaceHierarchyChild.readContent)
  final IList<String> via = const .empty(),
  @JsonKey(readValue: SpaceHierarchyChild.readContent)
  final bool suggested = false,
}) with _$SpaceHierarchyChild {
  static Object? readContent(Map json, String key) => json["content"]?[key];

  factory SpaceHierarchyChild.fromJson(Map<String, Object?> json) =>
      _$SpaceHierarchyChildFromJson(json);
}
