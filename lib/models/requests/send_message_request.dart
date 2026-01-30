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
    @Default(Mentions()) @JsonKey(name: "mentions") Mentions mentions,
    @JsonKey(name: "relates_to") Relation? relation,
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

@Freezed(toJson: false)
abstract class Relation with _$Relation {
  const Relation._();

  const factory Relation({
    required String eventId,
    required RelationType relationType,
  }) = _Relation;

  Map<String, dynamic> toJson() {
    switch (relationType) {
      case RelationType.reply:
        return {
          "m.in_reply_to": {"event_id": eventId},
        };

      case RelationType.edit:
        return {"rel_type": "m.replace", "event_id": eventId};
    }
  }

  factory Relation.fromJson(Map<String, dynamic> json) =>
      _$RelationFromJson(json);
}
