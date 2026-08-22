import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space_edge.dart";

part "sync_data.freezed.dart";
part "sync_data.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SyncData({
  final bool clearState = false,
  final IMap<String, IMap<String, dynamic>> accountData = const IMap.empty(),
  final IMap<String, Room> rooms = const IMap.empty(),
  final ISet<String> leftRooms = const ISet.empty(),
  final IMap<String, IList<SpaceEdge>>? spaceEdges,
  final IList<String>? topLevelSpaces,
}) with _$SyncData {
  Map<String, Object?> toJson() => _$SyncDataToJson(this);

  factory SyncData.fromJson(Map<String, Object?> json) =>
      _$SyncDataFromJson(json);
}
