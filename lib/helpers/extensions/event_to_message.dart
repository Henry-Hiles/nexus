import "package:flutter/foundation.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:matrix/matrix.dart";

extension EventToMessage on Event {
  Future<Message?> toMessage({bool mustBeText = false}) async {
    final replyId = relationshipType == RelationshipTypes.reply
        ? relationshipEventId
        : null;
    final sender = (await fetchSenderUser()) ?? senderFromMemoryOrFallback;

    final newContent = content["m.new_content"] as Map<String, Object?>?;
    final metadata = {
      "formatted":
          newContent?["formatted_body"] ??
          newContent?["body"] ??
          content["formatted_body"] ??
          this.body,
      "eventType": type,
      "displayName": sender.displayName ?? sender.id,
      "txnId": transactionId,
    };

    final editedAt = relationshipType == RelationshipTypes.edit
        ? originServerTs
        : null;
    final body = newContent?["body"] as String? ?? this.body;
    final eventId = editedAt == null
        ? this.eventId
        : relationshipEventId ?? this.eventId;

    if (redacted && !mustBeText) return null;

    // TODO: Use server-generated preview if enabled when https://github.com/famedly/matrix-dart-sdk/issues/2195 is fixed.

    // final match = Uri.tryParse(
    //   RegExp(regexLink, caseSensitive: false).firstMatch(body)?.group(0) ?? "",
    // );

    // final preview = match == null
    //     ? null
    // : await room.client.getUrlPreview(match);

    final asText =
        Message.text(
              metadata: metadata,
              id: eventId,
              authorId: senderId,
              text: body,
              replyToMessageId: replyId,
              deliveredAt: originServerTs,
              editedAt: editedAt,
            )
            as TextMessage;

    if (mustBeText) return asText;

    return switch (type) {
      EventTypes.Encrypted => asText.copyWith(
        text: "Unable to decrypt message.",
        metadata: {"formatted": "Unable to decrypt message.", ...metadata},
      ),
      (EventTypes.Sticker || EventTypes.Message) => switch (messageType) {
        (MessageTypes.Sticker || MessageTypes.Image) => Message.image(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: text,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
        ),
        MessageTypes.Audio => Message.audio(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: text,
          replyToMessageId: replyId,
          source: (await getAttachmentUri()).toString(),
          deliveredAt: originServerTs,
          duration: Duration(hours: 1),
        ),
        MessageTypes.File => Message.file(
          name: content["filename"].toString(),
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
        ),
        _ => asText,
      },
      EventTypes.RoomMember => Message.system(
        metadata: metadata,
        id: eventId,
        authorId: senderId,
        text:
            "${senderFromMemoryOrFallback.calcDisplayname()} joined the room.",
      ),
      EventTypes.Redaction => null,
      _ =>
        kDebugMode
            ? Message.unsupported(
                metadata: metadata,
                id: eventId,
                authorId: senderId,
                replyToMessageId: replyId,
              )
            : null,
    };
  }
}
