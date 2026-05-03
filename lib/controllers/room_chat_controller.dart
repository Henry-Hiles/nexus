import "dart:async";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/controllers/messages_controller.dart";
import "package:nexus/controllers/new_events_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/models/configs/messages_config.dart";
import "package:nexus/models/configs/message_config.dart";
import "package:nexus/models/requests/get_related_events_request.dart";
import "package:nexus/models/requests/get_room_state_request.dart";
import "package:nexus/models/requests/paginate_request.dart";
import "package:nexus/models/requests/redact_event_request.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/send_event_request.dart";
import "package:nexus/models/requests/send_message_request.dart";
import "package:nexus/models/room.dart";

class RoomChatController extends AsyncNotifier<InMemoryChatController> {
  final String roomId;
  RoomChatController(this.roomId);

  @override
  Future<InMemoryChatController> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    var room = ref.read(RoomsController.provider)[roomId];
    if (room == null) return InMemoryChatController();
    final state = await client.getRoomState(
      GetRoomStateRequest(roomId: roomId),
    );

    ref
        .read(RoomsController.provider.notifier)
        .update(
          {
            roomId: Room(
              events: state,
              state: state.fold(
                const IMap.empty(),
                (previousValue, stateEvent) => previousValue.add(
                  stateEvent.type,
                  (previousValue[stateEvent.type] ?? const IMap.empty()).addAll(
                    IMap({
                      if (stateEvent.stateKey != null)
                        stateEvent.stateKey!: stateEvent.rowId,
                    }),
                  ),
                ),
              ),
            ),
          }.toIMap(),
          const ISet.empty(),
        );

    room = ref.read(RoomsController.provider)[roomId];
    if (room == null) return InMemoryChatController();

    final messages = await ref.watch(
      MessagesController.provider(
        MessagesConfig(
          room: room,
          events: room.timeline
              .map(
                (timelineRowTuple) => room!.events.firstWhereOrNull(
                  (event) => event.rowId == timelineRowTuple.eventRowId,
                ),
              )
              .nonNulls
              .toIList(),
        ),
      ).future,
    );
    final controller = InMemoryChatController(messages: messages.toList());

    ref.onDispose(
      ref.listen(NewEventsController.provider(roomId), (_, next) async {
        for (final event in next) {
          if (event.type == "m.reaction") {
            final message = controller.messages.firstWhereOrNull(
              (message) =>
                  message.id == event.content["m.relates_to"]?["event_id"],
            );
            final key = event.content["m.relates_to"]?["key"];
            if (message == null || key == null || !ref.mounted) return;

            return await controller.updateMessage(
              message,
              message.copyWith(
                reactions: IMap(message.reactions)
                    .update(
                      key,
                      (reactors) => [...reactors, event.authorId],
                      ifAbsent: () => [event.authorId],
                    )
                    .unlock,
              ),
            );
          }

          if (event.type == "m.room.redaction") {
            final controller = await future;
            final redactsId = event.content["redacts"];
            final originalMessage = controller.messages.firstWhereOrNull(
              (message) => message.id == redactsId,
            );
            if (!ref.mounted) return;

            if (originalMessage != null) {
              return await controller.removeMessage(originalMessage);
            }

            final redacts = ref
                .read(SelectedRoomController.provider)
                ?.events
                .firstWhere((event) => event.eventId == redactsId);

            if (redacts?.type == "m.reaction") {
              final message = controller.messages.firstWhereOrNull(
                (message) =>
                    message.id == redacts!.content["m.relates_to"]?["event_id"],
              );
              final key = redacts!.content["m.relates_to"]?["key"];
              if (message == null || key == null || !ref.mounted) return;

              return await controller.updateMessage(
                message,
                message.copyWith(
                  reactions: IMap(message.reactions)
                      .update(
                        key,
                        (reactors) =>
                            IList(reactors).remove(redacts.authorId).unlock,
                      )
                      .where((_, value) => value.isNotEmpty)
                      .unlock,
                ),
              );
            }
          } else {
            final message = await ref.watch(
              MessageController.provider(
                MessageConfig(event: event, room: room!, includeEdits: true),
              ).future,
            );
            if (event.relationType == "m.replace") {
              final controller = await future;
              final oldMessage = controller.messages.firstWhereOrNull(
                (element) => element.id == event.relatesTo,
              );
              if (oldMessage == null || message == null || !ref.mounted) return;

              return await controller.updateMessage(
                oldMessage,
                message.copyWith(
                  id: oldMessage.id,
                  replyToMessageId: oldMessage.replyToMessageId,
                  metadata: {
                    ...(oldMessage.metadata ?? {}),
                    ...(message.metadata ?? {})
                        .toIMap()
                        .where((key, value) => value != null)
                        .unlock,
                  },
                ),
              );
            }
            if (message != null && ref.mounted) {
              await insertMessage(message);
            }
          }
        }
      }, weak: true).close,
    );

    ref.onDispose(controller.dispose);

    // While there are under 20 messages, try up to load more messages until theres no more or we have 20 messages.
    for (var more = true; more == true && controller.messages.length < 20;) {
      more = await loadOlder(controller);
    }

    return controller;
  }

  Future<void> insertMessage(Message message) async {
    final controller = await future;
    final oldMessage = message.metadata?["txnId"] == null
        ? null
        : controller.messages.firstWhereOrNull(
            (element) =>
                element.metadata?["txnId"] == message.metadata?["txnId"],
          );

    return oldMessage == null
        ? controller.insertMessage(message)
        : controller.updateMessage(oldMessage, message);
  }

  Future<void> deleteMessage(Message message, {String? reason}) => ref
      .watch(ClientController.provider.notifier)
      .redactEvent(
        RedactEventRequest(eventId: message.id, roomId: roomId, reason: reason),
      );

  Future<bool> loadOlder([InMemoryChatController? chatController]) async {
    final response = await ref
        .watch(ClientController.provider.notifier)
        .paginate(
          PaginateRequest(
            roomId: roomId,
            maxTimelineId: ref
                .read(RoomsController.provider)[roomId]
                ?.timeline
                .firstOrNull
                ?.timelineRowId,
          ),
        );

    ref
        .watch(RoomsController.provider.notifier)
        .update(
          IMap({
            roomId: Room(
              events: response.events.addAll(response.relatedEvents),
              hasMore: response.hasMore,
              timeline: response.events
                  .map(
                    (event) => TimelineRowTuple(
                      timelineRowId: event.timelineRowId,
                      eventRowId: event.rowId,
                    ),
                  )
                  .toIList(),
            ),
          }),
          const ISet.empty(),
          addToNewEvents: false,
        );

    final room = ref.read(RoomsController.provider)[roomId];
    if (room != null) {
      final messages = await ref.watch(
        MessagesController.provider(
          MessagesConfig(room: room, events: response.events.reversed),
        ).future,
      );

      final controller = chatController ?? await future;
      await controller.insertAllMessages(
        messages
            .where(
              (newMessage) => !controller.messages.any(
                (message) => message.id == newMessage.id,
              ),
            )
            .toList(),
        index: 0,
      );
    }
    return response.hasMore;
  }

  Future<void> send(
    String text, {
    bool shouldMention = true,
    required IList<Tag> tags,
    required RelationType relationType,
    Message? relation,
  }) async {
    var taggedMessage = text;

    for (final tag in tags) {
      final escaped = RegExp.escape(tag.id);
      final pattern = RegExp(r"@+(" + escaped + r")(#[^#]*#)?");

      taggedMessage = taggedMessage.replaceAllMapped(
        pattern,
        (match) => match.group(1)!,
      );
    }

    final client = ref.watch(ClientController.provider.notifier);
    final room = ref.read(RoomsController.provider)[roomId];
    final event = await client.sendMessage(
      SendMessageRequest(
        roomId: roomId,
        mentions: Mentions(
          userIds: [
            if (shouldMention == true &&
                relation != null &&
                relationType == RelationType.reply)
              relation.authorId,
          ].toIList(),
          room: taggedMessage.contains("@room"),
        ),
        text: taggedMessage,
        relation: relation == null
            ? null
            : Relation(eventId: relation.id, relationType: relationType),
      ),
    );
    final message = room == null
        ? null
        : await ref.watch(
            MessageController.provider(
              MessageConfig(room: room, event: event),
            ).future,
          );

    if (message != null) insertMessage(message);
  }

  Future<void> scrollToMessage(Message message) async {
    final controller = await future;
    Future<void> setFlashing(bool flashing) => controller.updateMessage(
      message,
      message.copyWith(
        metadata: {...(message.metadata ?? {}), "flashing": flashing},
      ),
    );

    await setFlashing(true);
    Timer(Duration(seconds: 1), () => setFlashing(false));

    return await controller.scrollToMessage(message.id);
  }

  Future<void> removeReaction(
    String reaction,
    Message message,
    String userId,
  ) async {
    final client = ref.watch(ClientController.provider.notifier);
    final allReactionEvents = await client.getRelatedEvents(
      GetRelatedEventsRequest(
        roomId: roomId,
        eventId: message.id,
        relationType: "m.annotation",
      ),
    );

    final reactionEvents = allReactionEvents
        ?.where((event) => event.redactedBy == null)
        .toIList();

    final reactionEvent = reactionEvents?.firstWhereOrNull(
      (event) =>
          event.authorId == userId &&
          event.content["m.relates_to"]?["key"] == reaction,
    );

    if (reactionEvent != null) {
      await ref
          .watch(ClientController.provider.notifier)
          .redactEvent(
            RedactEventRequest(eventId: reactionEvent.eventId, roomId: roomId),
          );
    }
  }

  Future<void> sendReaction(String reaction, Message message) async {
    final client = ref.watch(ClientController.provider.notifier);

    await client.sendEvent(
      SendEventRequest(
        roomId: roomId,
        type: "m.reaction",
        content: {
          "m.relates_to": {
            "event_id": message.id,
            "rel_type": "m.annotation",
            "key": reaction,
          },
        },
        synchronous: true,
        disableEncryption: true,
      ),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, InMemoryChatController, String>(
        RoomChatController.new,
      );
}
