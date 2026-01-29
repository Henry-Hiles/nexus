import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/relation_type.dart";
part "send_message_request.freezed.dart";
part "send_message_request.g.dart";

@freezed
abstract class SendMessageRequest with _$SendMessageRequest {
  const factory SendMessageRequest({
    required String roomId,
    required String text,
    @Default(Mentions()) @JsonKey(name: "m.mentions") Mentions mentions,
    @JsonKey(name: "m.relates_to") Relation? relation,
  }) = _SendMessageRequest;

  factory SendMessageRequest.fromJson(Map<String, Object?> json) =>
      _$SendMessageRequestFromJson(json);
}

@freezed
abstract class Mentions with _$Mentions {
  const factory Mentions({
    @Default(false) bool room,
    @Default(IList.empty()) IList<String> userIds,
  }) = _Mentions;

  factory Mentions.fromJson(Map<String, Object?> json) =>
      _$MentionsFromJson(json);
}

@freezed
abstract class Relation with _$Relation {
  const Relation._(); // required for custom methods

  const factory Relation({
    required String eventId,
    required RelationType relationType,
  }) = _Relation;

  @override
  Map<String, Object?> toJson() {
    switch (relationType) {
      case RelationType.reply:
        return {
          "m.in_reply_to": {"event_id": eventId},
        };

      case RelationType.edit:
        return {"rel_type": "m.replace", "event_id": eventId};
    }
  }

  factory Relation.fromJson(Map<String, Object?> json) =>
      _$RelationFromJson(json);
}
