import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "join_room.freezed.dart";
part "join_room.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const JoinRoomRequest({
  required final String roomIdOrAlias,
  final IList<String> via = const IList.empty(),
}) with _$JoinRoomRequest {
  Map<String, Object?> toJson() => _$JoinRoomRequestToJson(this);

  factory JoinRoomRequest.fromJson(Map<String, Object?> json) =>
      _$JoinRoomRequestFromJson(json);
}
