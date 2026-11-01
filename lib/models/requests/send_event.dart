import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/requests/send_message.dart";

part "send_event.freezed.dart";
part "send_event.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SendEventRequest({
  required final String roomId,
  required final String type,
  required final Content content,
  // Merged into the content by toJson, as gomuks doesn't take these
  @JsonKey(includeToJson: false) final String? relatesTo,
  @JsonKey(includeToJson: false) final String? relationType,
  @JsonKey(includeToJson: false) final String? replyTo,
  @JsonKey(includeToJson: false) final Mentions? mentions,
  final bool synchronous = false,
  final bool disableEncryption = false,
}) with _$SendEventRequest {
  Map<String, Object?> toJson() {
    final content = this.content.toJson();

    return {
      ..._$SendEventRequestToJson(this),
      "content": {
        ...content,
        "m.mentions": ?mentions?.toJson(),
        if (relatesTo != null || replyTo != null)
          "m.relates_to": {
            ...((content["m.relates_to"] as Map<String, dynamic>?) ?? {}),
            if (relatesTo != null) ...{
              "event_id": relatesTo,
              "rel_type": relationType,
            },
            if (replyTo != null) "m.in_reply_to": {"event_id": replyTo},
          },
      },
    };
  }

  factory SendEventRequest.fromJson(Map<String, Object?> json) =>
      _$SendEventRequestFromJson(json);
}
