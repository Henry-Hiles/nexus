import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "create.freezed.dart";
part "create.g.dart";

@freezed
abstract class CreateContent extends Content with _$CreateContent {
  CreateContent._();
  factory CreateContent({
    @JsonKey(name: "creator") String? creatorId,

    @JsonKey(name: "additional_creators")
    @Default(IList.empty())
    IList<String> additionalCreatorIds,

    PreviousRoom? predecessor,

    @JsonKey(name: "m.federate") @Default(true) bool federated,

    @Default("1") String roomVersion,
    @JsonKey(unknownEnumValue: RoomType.room) RoomType? type,
  }) = _CreateContent;

  factory CreateContent.fromJson(Map<String, Object?> json) =>
      _$CreateContentFromJson(json);
}

enum RoomType {
  room,
  @JsonValue("m.space")
  space,
}

@freezed
abstract class PreviousRoom with _$PreviousRoom {
  const factory PreviousRoom({required String roomId}) = _PreviousRoom;

  factory PreviousRoom.fromJson(Map<String, Object?> json) =>
      _$PreviousRoomFromJson(json);
}
