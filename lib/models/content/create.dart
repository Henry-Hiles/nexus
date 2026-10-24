import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "create.freezed.dart";
part "create.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const CreateContent({
  @JsonKey(name: "additional_creators")
  final IList<String> additionalCreatorIds = const .empty(),
  final PreviousRoom? predecessor,
  @JsonKey(name: "m.federate") final bool federated = true,
  final String roomVersion = "1",
  @JsonKey(unknownEnumValue: RoomType.room) final RoomType? type,
}) extends Content with _$CreateContent {
  factory CreateContent.fromJson(Map<String, Object?> json) =>
      _$CreateContentFromJson(json);
}

enum RoomType {
  room,
  @JsonValue("m.space")
  space,
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PreviousRoom({required final String roomId}) with _$PreviousRoom {
  Map<String, Object?> toJson() => _$PreviousRoomToJson(this);

  factory PreviousRoom.fromJson(Map<String, Object?> json) =>
      _$PreviousRoomFromJson(json);
}
