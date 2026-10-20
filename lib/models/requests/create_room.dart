import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/encryption.dart";

part "create_room.freezed.dart";
part "create_room.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const CreateRoomRequest({
  final RoomVisibility? visibility,
  final String? roomAliasName,
  final String? name,
  final String? topic,
  final IList<String> invite = const .empty(),
  @JsonKey(name: "uk.timedout.msc4491.invite_reason")
  final String? inviteReason,
  final IList<InitialStateEvent> initialState = const .empty(),
  final RoomPreset? preset,
  final bool isDirect = false,
  final IMap<String, dynamic>? creationContent,
}) with _$CreateRoomRequest {
  Map<String, Object?> toJson() => _$CreateRoomRequestToJson(this);

  factory CreateRoomRequest.fromJson(Map<String, Object?> json) =>
      _$CreateRoomRequestFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const InitialStateEvent({
  required final String type,
  final String stateKey = "",
  required final Content content,
}) with _$InitialStateEvent {
  static final encryption = InitialStateEvent(
    type: EventType.encryption.type,
    content: EncryptionContent(algorithm: "m.megolm.v1.aes-sha2"),
  );

  Map<String, Object?> toJson() => _$InitialStateEventToJson(this);

  factory InitialStateEvent.fromJson(Map<String, Object?> json) =>
      _$InitialStateEventFromJson(json);
}

@JsonEnum(fieldRename: .snake)
enum RoomVisibility { public, private }

@JsonEnum(fieldRename: .snake)
enum RoomPreset { privateChat, publicChat, trustedPrivateChat }
