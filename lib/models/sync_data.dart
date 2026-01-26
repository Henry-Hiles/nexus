import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "sync_data.freezed.dart";
part "sync_data.g.dart";

@freezed
abstract class SyncData with _$SyncData {
  const factory SyncData({
    @Default(false) bool clearState,
    // required Map<String, AccountData> accountData,
    @Default({}) Map<String, Room> rooms,
    @Default([]) List<String> leftRooms,
    // required List<InvitedRoom> invitedRooms,
    // required List<SpaceEdge> spaceEdges,
    @Default([]) List<String> topLevelSpaces,
  }) = _SyncData;

  factory SyncData.fromJson(Map<String, Object?> json) =>
      _$SyncDataFromJson(json);
}
