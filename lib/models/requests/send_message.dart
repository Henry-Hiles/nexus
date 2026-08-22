import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/relation_type.dart";

part "send_message.freezed.dart";
part "send_message.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SendMessageRequest({
  required final String roomId,
  required final String text,
  final Content? baseContent,
  @JsonKey(name: "mentions") final Mentions mentions = const Mentions(),
  @JsonKey(name: "relates_to") final Relation? relation,
}) with _$SendMessageRequest {
  Map<String, Object?> toJson() => _$SendMessageRequestToJson(this);

  factory SendMessageRequest.fromJson(Map<String, Object?> json) =>
      _$SendMessageRequestFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Mentions({
  final bool room = false,
  final IList<String> userIds = const IList.empty(),
}) with _$Mentions {
  Map<String, Object?> toJson() => _$MentionsToJson(this);

  factory Mentions.fromJson(Map<String, Object?> json) =>
      _$MentionsFromJson(json);
}

@Freezed(toJson: false)
class const Relation({
  required final String eventId,
  required final RelationType relationType,
}) with _$Relation {
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
