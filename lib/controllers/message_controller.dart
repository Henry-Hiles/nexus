import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/configs/message_config.dart";
import "package:nexus/models/requests/get_related_events_request.dart";

class MessageController extends AsyncNotifier<Message?> {
  final MessageConfig config;
  MessageController(this.config);

  @override
  Future<Message?> build() async {
    try {
      final isEdit = config.event.relationType == "m.replace";
      if ((isEdit && !config.includeEdits) || config.room.metadata == null) {
        return null;
      }

      final event = config.event.lastEditRowId == null
          ? config.event
          : config.room.events.firstWhereOrNull(
                  (e) => e.rowId == config.event.lastEditRowId,
                ) ??
                config.event;

      final decrypted = (event.decrypted ?? event.content);
      final type = (config.event.decryptedType ?? config.event.type);
      final content = decrypted["m.new_content"] == null
          ? decrypted
          : IMap(decrypted["m.new_content"]);

      final homeserver = ref
          .read(ClientStateController.provider)
          ?.homeserverUrl;
      final source = homeserver == null || content["url"] == null
          ? "null"
          : Uri.parse(content["url"]).mxcToHttps(homeserver).toString();

      final metadata = {
        "body": config.event.redactedBy == null
            ? (content["body"] ?? "")
            : "Deleted Message",
        "flashing": false,
        "timelineId": event.timelineRowId,
        "big": event.localContent?.bigEmoji == true,
        "eventType": type,
        "pmp": content["com.beeper.per_message_profile"],
        "error": event.sendError,
        "format": content["format"] ?? content["format"],
        "editSource": event.localContent?.editSource ?? content["body"],
        "txnId": config.event.transactionId,
      };

      final editedAt = event.relationType == "m.replace"
          ? event.timestamp
          : null;

      if ((event.redactedBy != null && !config.alwaysReturn) ||
          (!config.includeEdits &&
              (config.event.relationType == "m.replace"))) {
        return null;
      }

      final replyId =
          config.event.content["m.relates_to"]?["m.in_reply_to"]?["event_id"];

      final reactionEvents = config.event.reactions.isEmpty && !isEdit
          ? null
          : await ref
                .watch(ClientController.provider.notifier)
                .getRelatedEvents(
                  GetRelatedEventsRequest(
                    roomId: config.room.metadata!.id,
                    eventId:
                        (isEdit ? config.event.relatesTo : null) ??
                        config.event.eventId,
                    relationType: "m.annotation",
                  ),
                );

      final reactions = reactionEvents
          ?.where((event) => event.redactedBy == null)
          .fold<IMap<String, IList<String>>>(IMap(), (acc, event) {
            final key = event.content["m.relates_to"]?["key"];
            if (key == null) return acc;

            return acc.update(
              key,
              (list) => list.add(event.authorId),
              ifAbsent: () => IList([event.authorId]),
            );
          })
          .map((key, value) => MapEntry(key, value.unlock))
          .unlock;

      final asText =
          Message.text(
                metadata: metadata,
                id: config.event.eventId,
                reactions: reactions,
                authorId: event.authorId,
                text: content["formatted_body"] ?? content["body"] ?? "",
                replyToMessageId: replyId,
                deliveredAt: config.event.timestamp,
                editedAt: editedAt,
              )
              as TextMessage;

      Message toSystemMessage(String content) => Message.system(
        metadata: {...metadata, "body": content},
        id: config.event.eventId,
        reactions: reactions,
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
            reactions: reactions,
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
            reactions: reactions,
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
                        reactions: reactions,
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
