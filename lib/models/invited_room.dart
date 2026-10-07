import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/event.dart";

part "invited_room.freezed.dart";
part "invited_room.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const InvitedRoom({
  required final String roomId,
  @EpochDateTimeConverter() required final DateTime createdAt,
  // TODO: This is DBEvent, should be event.Event
  required final IList<Event> inviteState,
}) with _$InvitedRoom {
  Map<String, Object?> toJson() => _$InvitedRoomToJson(this);

  factory InvitedRoom.fromJson(Map<String, Object?> json) =>
      _$InvitedRoomFromJson(json);
}
