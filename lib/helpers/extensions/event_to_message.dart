import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:matrix/matrix.dart";

extension EventToMessage on Event {
  Future<Message?> toMessage({
    bool mustBeText = false,
    bool includeEdits = false,
  }) async {
    final replyId = inReplyToEventId();
    final newEvent = (unsigned?["m.relations"] as Map?)?["m.replace"];
    final event = newEvent == null ? this : Event.fromJson(newEvent, room);

    final replyEvent = replyId == null
        ? null
        : await room.getEventById(replyId);

    final sender =
        await event.fetchSenderUser() ?? event.senderFromMemoryOrFallback;
    final newContent = event.content["m.new_content"] as Map?;
    final metadata = {
      "formatted":
          newContent?["formatted_body"] ??
          newContent?["body"] ??
          event.content["formatted_body"] ??
          event.content["body"] ??
          "",
      "reply": await replyEvent?.toMessage(mustBeText: true),
      "body": newContent?["body"] ?? event.content["body"],
      "eventType": event.type,
      "avatarUrl": sender.avatarUrl.toString(),
      "displayName": sender.displayName ?? sender.id,
      "txnId": transactionId,
    };

    final editedAt = event.relationshipType == RelationshipTypes.edit
        ? event.originServerTs
        : null;

    if ((redacted && !mustBeText) ||
        (!includeEdits && (relationshipType == RelationshipTypes.edit))) {
      return null;
    }

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
              text: redacted ? "This message has been deleted..." : event.body,
              replyToMessageId: replyId,
              deliveredAt: originServerTs,
              editedAt: editedAt,
            )
            as TextMessage;

    if (mustBeText) return asText;

    return switch (type) {
      EventTypes.Encrypted => asText.copyWith(
        text: "Unable to decrypt message.",
        metadata: {...metadata, "formatted": "Unable to decrypt message."},
      ),
      (EventTypes.Sticker || EventTypes.Message) => switch (messageType) {
        (MessageTypes.Sticker || MessageTypes.Image) => Message.image(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: event.text,
          source: (await getAttachmentUri()).toString(),
          replyToMessageId: replyId,
          deliveredAt: originServerTs,
          blurhash: (event.content["info"] as Map?)?["xyz.amorgan.blurhash"],
        ),
        MessageTypes.Audio => Message.audio(
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          text: event.text,
          replyToMessageId: replyId,
          source: (await event.getAttachmentUri()).toString(),
          deliveredAt: originServerTs,
          // TODO: See if we can figure out duration
          duration: Duration(hours: 1),
        ),
        MessageTypes.File => Message.file(
          name: event.content["filename"].toString(),
          metadata: metadata,
          id: eventId,
          authorId: senderId,
          source: (await event.getAttachmentUri()).toString(),
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
            "${event.asUser.displayName ?? event.asUser.id} ${switch (Membership.values.firstWhereOrNull((membership) => membership.name == event.content["membership"])) {
              Membership.invite => "was invited to",
              Membership.join => "joined",
              Membership.leave => "left",
              Membership.knock => "asked to join",
              Membership.ban => "was banned from",
              _ => "did something relating to",
            }} the room.",
      ),
      EventTypes.Redaction => null,
      _ =>
        // Turn this on for debugging purposes
        false
            // ignore: dead_code
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
