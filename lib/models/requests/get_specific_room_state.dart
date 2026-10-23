import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "get_specific_room_state.freezed.dart";
part "get_specific_room_state.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetSpecificRoomStateRequest({
  required final IList<RoomStateKey> keys,
}) with _$GetSpecificRoomStateRequest {
  Map<String, Object?> toJson() => _$GetSpecificRoomStateRequestToJson(this);

  factory GetSpecificRoomStateRequest.fromJson(Map<String, Object?> json) =>
      _$GetSpecificRoomStateRequestFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RoomStateKey({
  required final String roomId,
  required final String type,
  required final String stateKey,
}) with _$RoomStateKey {
  Map<String, Object?> toJson() => _$RoomStateKeyToJson(this);

  factory RoomStateKey.fromJson(Map<String, Object?> json) =>
      _$RoomStateKeyFromJson(json);
}
