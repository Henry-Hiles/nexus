import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/message_config.dart";
import "package:nexus/models/requests/get_event_request.dart";
import "package:nexus/models/requests/get_related_events_request.dart";

class MessageController extends AsyncNotifier<Message?> {
  final MessageConfig config;
  MessageController(this.config);

  @override
  Future<Message?> build() async {
    if (config.event.relationType == "m.replace" && !config.includeEdits) {
      return null;
    }
    final client = ref.watch(ClientController.provider.notifier);

    final newEvents = await client.getRelatedEvents(
      GetRelatedEventsRequest(
        roomId: config.event.roomId,
        eventId: config.event.eventId,
        relationType: "m.replace",
      ),
    );
    if (!ref.mounted) return null;
    final event = newEvents?.lastOrNull ?? config.event;

    final replyId =
        config.event.content["m.relates_to"]?["m.in_reply_to"]?["event_id"];
    final replyEvent = replyId == null
        ? null
        : await client.getEvent(
            GetEventRequest(roomId: config.event.roomId, eventId: replyId),
          );

    if (!ref.mounted) return null;

    final author = await ref.read(
      ProfileController.provider(event.authorId).future,
    );
    if (!ref.mounted) return null;

    final content = (event.decrypted ?? event.content);
    final type = (config.event.decryptedType ?? config.event.type);
    final newContent = content["m.new_content"] as Map?;
    final metadata = {
      "timelineId": event.timelineRowId,
      "formatted":
          newContent?["formatted_body"] ??
          newContent?["body"] ??
          content["formatted_body"] ??
          content["body"] ??
          "",
      if (replyEvent != null)
        "reply": await ref.watch(
          MessageController.provider(
            MessageConfig(event: replyEvent, mustBeText: true),
          ).future,
        ),
      "body": newContent?["body"] ?? content["body"],
      "eventType": type,
      "avatarUrl": author.avatarUrl,
      "displayName": author.displayName ?? event.authorId,
      "txnId": config.event.transactionId,
    };

    if (!ref.mounted) return null;

    final editedAt = event.relationType == "m.replace" ? event.timestamp : null;

    if ((event.redactedBy != null && !config.mustBeText) ||
        (!config.includeEdits && (config.event.relationType == "m.replace"))) {
      return null;
    }

    // TODO: Use server-generated preview if enabled

    // final match = Uri.tryParse(
    //   RegExp(regexLink, caseSensitive: false).firstMatch(body)?.group(0) ?? "",
    // );

    final asText =
        Message.text(
              metadata: metadata,
              id: config.event.eventId,
              authorId: event.authorId,
              text: config.event.redactedBy == null
                  ? content["body"] ?? ""
                  : "This message has been deleted...",
              replyToMessageId: replyId,
              deliveredAt: config.event.timestamp,
              editedAt: editedAt,
            )
            as TextMessage;

    if (config.mustBeText) return asText;

    final homeserver = ref.read(ClientStateController.provider)?.homeserverUrl;
    final source = homeserver == null || content["url"] == null
        ? "null"
        : Uri.parse(content["url"]).mxcToHttps(homeserver).toString();

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
        (null || "m.image") => Message.image(
          id: config.event.eventId,
          metadata: metadata,
          authorId: event.authorId,
          text: event.localContent?.sanitizedHtml,
          source: source,
          replyToMessageId: replyId,
          deliveredAt: config.event.timestamp,
          blurhash: (content["info"] as Map?)?["xyz.amorgan.blurhash"],
        ),
        "m.audio" => Message.audio(
          id: config.event.eventId,
          metadata: metadata,
          authorId: event.authorId,
          text: content["body"],
          replyToMessageId: replyId,
          source: source,
          deliveredAt: config.event.timestamp,
          // TODO: See if we can figure out duration
          duration: Duration(hours: 1),
        ),
        "m.file" => Message.file(
          name: content["filename"].toString(),
          metadata: metadata,
          id: config.event.eventId,
          authorId: event.authorId,
          source: source,
          replyToMessageId: replyId,
          deliveredAt: config.event.timestamp,
        ),
        _ => asText,
      },
      "m.room.member" => Message.system(
        metadata: metadata,
        id: config.event.eventId,
        authorId: event.authorId,
        deliveredAt: config.event.timestamp,
        text:
            "${content["displayname"] ?? event.stateKey} ${switch (content["membership"]) {
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
                id: config.event.eventId,
                authorId: event.authorId,
                replyToMessageId: replyId,
              )
            : null,
    };
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MessageController, Message?, MessageConfig>(
        MessageController.new,
      );
}
