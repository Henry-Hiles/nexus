import "package:freezed_annotation/freezed_annotation.dart";

part "get_room_state.freezed.dart";
part "get_room_state.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetRoomStateRequest({
  required final String roomId,
  final bool refetch = false,
  final bool fetchMembers = false,
  final bool includeMembers = false,
}) with _$GetRoomStateRequest {
  Map<String, Object?> toJson() => _$GetRoomStateRequestToJson(this);

  factory GetRoomStateRequest.fromJson(Map<String, Object?> json) =>
      _$GetRoomStateRequestFromJson(json);
}
