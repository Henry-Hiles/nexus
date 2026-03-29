import "package:freezed_annotation/freezed_annotation.dart";
part "get_room_state_request.freezed.dart";
part "get_room_state_request.g.dart";

@freezed
abstract class GetRoomStateRequest with _$GetRoomStateRequest {
  const factory GetRoomStateRequest({
    required String roomId,
    @Default(false) bool refetch,
    @Default(false) bool fetchMembers,
    @Default(false) bool includeMembers,
  }) = _GetRoomStateRequest;

  factory GetRoomStateRequest.fromJson(Map<String, Object?> json) =>
      _$GetRoomStateRequestFromJson(json);
}
