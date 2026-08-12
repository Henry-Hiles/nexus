import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "join_room.freezed.dart";
part "join_room.g.dart";

@freezed
abstract class JoinRoomRequest with _$JoinRoomRequest {
  const factory JoinRoomRequest({
    required String roomIdOrAlias,
    @Default(IList.empty()) IList<String> via,
  }) = _JoinRoomRequest;

  factory JoinRoomRequest.fromJson(Map<String, Object?> json) =>
      _$JoinRoomRequestFromJson(json);
}
