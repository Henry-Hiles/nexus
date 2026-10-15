import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/matrix_event.dart";

part "invited_room.freezed.dart";
part "invited_room.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const InvitedRoom({
  required final String roomId,
  final IList<MatrixEvent> inviteState = const .empty(),
}) with _$InvitedRoom {
  factory InvitedRoom.fromJson(Map<String, Object?> json) =>
      _$InvitedRoomFromJson(json);
}
