import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/controllers/messages_controller.dart";
import "package:nexus/controllers/new_events_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/models/message_config.dart";
import "package:nexus/models/requests/get_room_state_request.dart";
import "package:nexus/models/requests/paginate_request.dart";
import "package:nexus/models/requests/redact_event_request.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/requests/send_message_request.dart";
import "package:nexus/models/room.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  final String roomId;
  RoomChatController(this.roomId);

  @override
  Future<ChatController> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    final room = ref.read(SelectedRoomController.provider);
    if (room == null) return InMemoryChatController();

    final messages = await ref.watch(
      MessagesController.provider(
        room.timeline
            .map(
              (timelineRowTuple) => room.events.firstWhereOrNull(
                (event) => event.rowId == timelineRowTuple.eventRowId,
              ),
            )
            .nonNulls
            .toIList(),
      ).future,
    );
    final controller = InMemoryChatController(messages: messages.toList());

    ref.onDispose(
      ref.listen(NewEventsController.provider(roomId), (_, next) async {
        final controller = await future;
        for (final event in next) {
          if (event.type == "m.room.redaction") {
            final controller = await future;
            final message = controller.messages.firstWhereOrNull(
              (message) => message.id == event.content["redacts"],
            );
            if (message == null || !ref.mounted) return;

            await controller.removeMessage(message);
          } else {
            final message = await ref.watch(
              MessageController.provider(
                MessageConfig(event: event, includeEdits: true),
              ).future,
            );
            if (event.relationType == "m.replace") {
              final controller = await future;
              final oldMessage = controller.messages.firstWhereOrNull(
                (element) => element.id == event.relatesTo,
              );
              if (oldMessage == null || message == null || !ref.mounted) return;

              return await updateMessage(
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
            if (message != null &&
                !controller.messages.any(
                  (oldMessage) => oldMessage.id == message.id,
                ) &&
                ref.mounted) {
              await controller.insertMessage(message);
            }
          }
        }
      }, weak: true).close,
    );

    ref.onDispose(controller.dispose);

    if (messages.length < 20) await loadOlder(controller);

    final state = await client.getRoomState(
      GetRoomStateRequest(
        roomId: roomId,
        fetchMembers: room.metadata?.hasMemberList == false,
        includeMembers: true,
      ),
    );

    ref
        .watch(RoomsController.provider.notifier)
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

  Future<void> deleteMessage(Message message, {String? reason}) async {
    final controller = await future;
    await controller.removeMessage(message);
    await ref
        .watch(ClientController.provider.notifier)
        .redactEvent(
          RedactEventRequest(
            eventId: message.id,
            roomId: roomId,
            reason: reason,
          ),
        );
  }

  Future<void> loadOlder([InMemoryChatController? chatController]) async {
    final controller = chatController ?? await future;
    final client = ref.watch(ClientController.provider.notifier);

    final response = await client.paginate(
      PaginateRequest(
        roomId: roomId,
        maxTimelineId: controller.messages.firstOrNull?.metadata?["timelineId"],
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
        );

    final messages = await ref.watch(
      MessagesController.provider(response.events.reversed).future,
    );
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

  Future<void> updateMessage(Message message, Message newMessage) async =>
      (await future).updateMessage(message, newMessage);

  Future<void> send(
    String message, {
    required Iterable<Tag> tags,
    required RelationType relationType,
    Message? relation,
  }) async {
    var taggedMessage = message;

    for (final tag in tags) {
      final escaped = RegExp.escape(tag.id);
      final pattern = RegExp(r"@+(" + escaped + r")(#[^#]*#)?");

      taggedMessage = taggedMessage.replaceAllMapped(
        pattern,
        (match) => match.group(1)!,
      );
    }

    final client = ref.watch(ClientController.provider.notifier);
    client.sendMessage(
      SendMessageRequest(
        roomId: roomId,
        mentions: Mentions(
          userIds: [
            if (relation != null && relationType == RelationType.reply)
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
  }

  Future<chat.User> resolveUser(String id) async {
    final user = await ref
        .watch(ClientController.provider.notifier)
        .getProfile(id);
    return chat.User(
      id: id,
      name: user.displayName,
      // imageSource: user.avatarUrl == null
      //     ? null
      //     : (await ref.watch(
      //         AvatarController.provider(user.avatarUrl!.toString()).future,
      //       )).toString(),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, ChatController, String>(
        RoomChatController.new,
      );
}
