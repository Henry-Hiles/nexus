import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/invited_room.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space_edge.dart";

part "sync_data.freezed.dart";
part "sync_data.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const SyncData({
  final bool clearState = false,
  final IMap<String, IMap<String, dynamic>> accountData = const .empty(),
  final IMap<String, Room> rooms = const .empty(),
  final ISet<String> leftRooms = const .empty(),
  final IList<InvitedRoom> invitedRooms = const .empty(),
  final IMap<String, IList<SpaceEdge>>? spaceEdges,
  final IList<String>? topLevelSpaces,
}) with _$SyncData {
  factory SyncData.fromJson(Map<String, Object?> json) =>
      _$SyncDataFromJson(json);
}
