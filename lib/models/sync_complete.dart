import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "sync_complete.freezed.dart";
part "sync_complete.g.dart";

@freezed
abstract class SyncComplete with _$SyncComplete {
  const factory SyncComplete({
    @Default(false) bool clearState,
    // required Map<String, AccountData> accountData,
    required Map<String, Room> rooms,
    required List<String> leftRooms,
    // required List<InvitedRoom> invitedRooms,
    // required List<SpaceEdge> spaceEdges,
    required List<String> topLevelSpaces,
  }) = _SyncComplete;

  factory SyncComplete.fromJson(Map<String, Object?> json) =>
      _$SyncCompleteFromJson(json);
}
