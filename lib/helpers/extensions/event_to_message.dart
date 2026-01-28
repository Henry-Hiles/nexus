import "dart:developer";

import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/get_event_request.dart";
import "package:nexus/models/get_related_events_request.dart";

extension EventToMessage on Event {
  Future<Message?> toMessage(
    ClientController client, {
    bool mustBeText = false,
    bool includeEdits = false,
  }) async {
    if (relationType == "m.replace" && !includeEdits) return null;

    final newEvents = await client.getRelatedEvents(
      GetRelatedEventsRequest(
        roomId: roomId,
        eventId: eventId,
        relationType: "m.replace",
      ),
    );
    final event = newEvents?.lastOrNull ?? this;

    final replyId = this.content["m.relates_to"]?["m.in_reply_to"]?["event_id"];
    final replyEvent = replyId == null
        ? null
        : await client.getEvent(
            GetEventRequest(roomId: roomId, eventId: replyId),
          );

    final author = await client.getProfile(event.authorId);
    final newContent = event.content["m.new_content"] as Map?;
    final metadata = {
      "formatted":
          newContent?["formatted_body"] ??
          newContent?["body"] ??
          event.content["formatted_body"] ??
          event.content["body"] ??
          "",
      "reply": await replyEvent?.toMessage(client, mustBeText: true),
      "body": newContent?["body"] ?? event.content["body"],
      "eventType": event.type,
      "avatarUrl": author?.avatarUrl,
      "displayName": author?.displayName ?? authorId,
      "txnId": transactionId,
    };

    final editedAt = event.relationType == "m.replace" ? event.timestamp : null;

    if ((event.redactedBy != null && !mustBeText) ||
        (!includeEdits && (relationType == "m.replace"))) {
      return null;
    }

    // TODO: Use server-generated preview if enabled

    // final match = Uri.tryParse(
    //   RegExp(regexLink, caseSensitive: false).firstMatch(body)?.group(0) ?? "",
    // );

    final asText =
        Message.text(
              metadata: metadata,
              id: eventId,
              authorId: authorId,
              text: redactedBy == null
                  ? event.content["body"] ?? ""
                  : "This message has been deleted...",
              replyToMessageId: replyId,
              deliveredAt: timestamp,
              editedAt: editedAt,
            )
            as TextMessage;

    final content = (decrypted ?? this.content);

    if (mustBeText) return asText;
    return switch (type) {
      "m.room.encrypted" => asText.copyWith(
        text: "Unable to decrypt message.",
        metadata: {...metadata, "formatted": "Unable to decrypt message."},
      ),
      // "org.matrix.msc3381.poll.start" => Message.custom(
      //   metadata: {
      //     ...metadata,
      //     "poll": event.parsedPollEventContent.pollStartContent,
      //     "responses": event.getPollResponses(timeline),
      //   },
      //   id: eventId,
      //   deliveredAt: originServerTs,
      //   authorId: senderId,
      // ),
      ("m.sticker" || "m.room.message") => switch (content["msgtype"]) {
        ("m.sticker" || "m.image") => Message.image(
          metadata: metadata,
          id: eventId,
          authorId: authorId,
          text: event.localContent?.sanitizedHtml,
          source: "(await getAttachmentUri()).toString()", // TODO
          replyToMessageId: replyId,
          deliveredAt: timestamp,
          blurhash: (event.content["info"] as Map?)?["xyz.amorgan.blurhash"],
        ),
        "m.audio" => Message.audio(
          metadata: metadata,
          id: eventId,
          authorId: authorId,
          text: event.content["body"],
          replyToMessageId: replyId,
          source: "(await event.getAttachmentUri()).toString()", // TODO
          deliveredAt: timestamp,
          // TODO: See if we can figure out duration
          duration: Duration(hours: 1),
        ),
        "m.file" => Message.file(
          name: event.content["filename"].toString(),
          metadata: metadata,
          id: eventId,
          authorId: authorId,
          source: "(await event.getAttachmentUri()).toString()", // TODO
          replyToMessageId: replyId,
          deliveredAt: timestamp,
        ),
        _ => asText,
      },
      "m.room.member" => Message.system(
        metadata: metadata,
        id: eventId,
        authorId: authorId,
        deliveredAt: timestamp,
        text:
            "${content["displayname"] ?? event.stateKey} ${switch (event.content["membership"]) {
              "invite" => "was invited to",
              "join" => "joined",
              "leave" => "left",
              "knock" => "asked to join",
              "ban" => "was banned from",
              _ => "did something relating to",
            }} the room.",
      ),
      "m.room.redaction" => null,
      _ =>
        // Turn this on for debugging purposes
        false
            // ignore: dead_code
            ? Message.unsupported(
                metadata: metadata,
                id: eventId,
                authorId: authorId,
                replyToMessageId: replyId,
              )
            : null,
    };
  }
}
