import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/configs/message_config.dart";

class MessageController extends AsyncNotifier<Message?> {
  final MessageConfig config;
  MessageController(this.config);

  @override
  Future<Message?> build() async {
    try {
      if (config.event.relationType == "m.replace" && !config.includeEdits) {
        return null;
      }

      if (!ref.mounted) return null;
      final event = config.event.lastEditRowId == null
          ? config.event
          : config.room.events.firstWhereOrNull(
                  (e) => e.rowId == config.event.lastEditRowId,
                ) ??
                config.event;

      if (!ref.mounted) return null;

      final content = (event.decrypted ?? event.content);
      final type = (config.event.decryptedType ?? config.event.type);
      final newContent = content["m.new_content"] as Map?;

      final homeserver = ref
          .read(ClientStateController.provider)
          ?.homeserverUrl;
      final source = homeserver == null || content["url"] == null
          ? "null"
          : Uri.parse(content["url"]).mxcToHttps(homeserver).toString();

      final metadata = {
        "body": config.event.redactedBy == null
            ? (newContent?["body"] ?? content["body"] ?? "")
            : "Deleted Message",
        "flashing": false,
        "timelineId": event.timelineRowId,
        "big": event.localContent?.bigEmoji == true,
        "eventType": type,
        "pmp": event.content["com.beeper.per_message_profile"],
        "error": event.sendError,
        "format": content["format"],
        "editSource":
            event.localContent?.editSource ??
            newContent?["body"] ??
            content["body"],
        "txnId": config.event.transactionId,
      };

      if (!ref.mounted) return null;

      final editedAt = event.relationType == "m.replace"
          ? event.timestamp
          : null;

      if ((event.redactedBy != null && !config.alwaysReturn) ||
          (!config.includeEdits &&
              (config.event.relationType == "m.replace"))) {
        return null;
      }

      // TODO: Use server-generated preview if enabled

      // final match = Uri.tryParse(
      //   RegExp(regexLink, caseSensitive: false).firstMatch(body)?.group(0) ?? "",
      // );

      final replyId =
          config.event.content["m.relates_to"]?["m.in_reply_to"]?["event_id"];

      final asText =
          Message.text(
                metadata: metadata,
                id: config.event.eventId,
                authorId: event.authorId,
                text:
                    newContent?["formatted_body"] ??
                    newContent?["body"] ??
                    content["formatted_body"] ??
                    content["body"] ??
                    "",
                replyToMessageId: replyId,
                deliveredAt: config.event.timestamp,
                editedAt: editedAt,
              )
              as TextMessage;

      Message toSystemMessage(String content) => Message.system(
        metadata: {...metadata, "body": content},
        id: config.event.eventId,
        authorId: event.authorId,
        deliveredAt: config.event.timestamp,
        text: content,
      );

      return switch (type) {
        "m.room.encrypted" => asText.copyWith(
          text: "Unable to decrypt message.",
          metadata: {...metadata, "body": "Unable to decrypt message."},
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
          null || "m.image" => Message.image(
            id: config.event.eventId,
            authorId: event.authorId,
            source: source,
            replyToMessageId: replyId,
            metadata: metadata,
            text: asText.text,
            deliveredAt: config.event.timestamp,
            blurhash: (content["info"] as Map?)?["xyz.amorgan.blurhash"],
          ),
          "m.audio" || "m.file" => Message.file(
            name: content["filename"].toString(),
            size: content["info"]["size"],
            metadata: metadata,
            id: config.event.eventId,
            authorId: event.authorId,
            source: source,
            replyToMessageId: replyId,
            deliveredAt: config.event.timestamp,
          ),
          _ => asText,
        },
        "m.room.member" =>
          content["membership"] == event.unsigned["prev_content"]?["membership"]
              ? null
              : toSystemMessage(
                  "${content["displayname"] ?? event.stateKey} ${switch (content["membership"]) {
                    "invite" => "was invited to",
                    "join" => "joined",
                    "leave" => event.authorId == event.stateKey ? "left" : (event.unsigned["prev_content"]?["membership"] == "ban" ? "was unbanned from" : "was kicked from"),
                    "ban" => "was banned from",
                    "knock" => "asked to join",
                    _ => "did something relating to",
                  }} the room. ${content["reason"] ?? ""}",
                ),

        "m.room.server_acl" => toSystemMessage(
          "${event.authorId} updated the server ban list.",
        ),

        "m.room.redaction" =>
          config.alwaysReturn
              ? asText.copyWith(
                  metadata: {
                    ...(asText.metadata ?? {}),
                    "body": "Deleted Message",
                  },
                )
              : null,
        _ =>
          config.alwaysReturn
              ? asText
              : (
                // Turn this on for debugging purposes
                false
                    // ignore: dead_code
                    ? Message.unsupported(
                        metadata: metadata,
                        id: config.event.eventId,
                        authorId: event.authorId,
                        replyToMessageId: replyId,
                      )
                    : null),
      };
    } catch (error) {
      return null;
    }
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MessageController, Message?, MessageConfig>(
        MessageController.new,
      );
}
