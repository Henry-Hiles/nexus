import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "sync_data.freezed.dart";
part "sync_data.g.dart";

@freezed
abstract class SyncData with _$SyncData {
  const factory SyncData({
    @Default(false) bool clearState,
    // required IMap<String, AccountData> accountData,
    @Default(IMap.empty()) IMap<String, Room> rooms,
    @Default(ISet.empty()) ISet<String> leftRooms,
    // required IList<InvitedRoom> invitedRooms,
    // required IList<SpaceEdge> spaceEdges,
    @Default(IList.empty()) IList<String> topLevelSpaces,
  }) = _SyncData;

  factory SyncData.fromJson(Map<String, Object?> json) =>
      _$SyncDataFromJson(json);
}
