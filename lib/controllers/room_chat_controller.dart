import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/events_controller.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";
import "package:nexus/helpers/extensions/list_to_messages.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  final Room room;
  RoomChatController(this.room);

  @override
  Future<ChatController> build() async {
    final response = await ref.watch(EventsController.provider(room).future);

    ref.onDispose(
      room.client.onTimelineEvent.stream.listen((event) async {
        if (event.roomId != room.id) return;

        if (event.type == EventTypes.Redaction) {
          final controller = await future;
          await controller.removeMessage(
            controller.messages.firstWhere(
              (message) => message.id == event.redacts,
            ),
          );
        } else {
          final message = await event.toMessage();
          if (message != null) {
            if (event.relationshipType == RelationshipTypes.edit) {
              final controller = await future;
              final oldMessage = controller.messages.firstWhereOrNull(
                (element) => element.id == event.relationshipEventId,
              );
              if (oldMessage == null) return;
              await updateMessage(oldMessage, message);
            } else {
              await insertMessage(message);
            }
          }
        }
      }).cancel,
    );

    return InMemoryChatController(
      messages: await response.chunk.toMessages(room),
    );
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
    await room.redactEvent(message.id, reason: reason);
  }

  Future<void> loadOlder() async {
    final controller = await future;
    final response = await ref
        .watch(EventsController.provider(room).notifier)
        .prev();

    await controller.insertAllMessages(
      await response.chunk.toMessages(room),
      index: 0,
    );
  }

  Future<void> markRead() async {
    if (!room.hasNewMessages) return;
    final controller = await future;
    final id = controller.messages.last.id;

    await room.setReadMarker(id, mRead: id);
  }

  Future<void> updateMessage(Message message, Message newMessage) async =>
      (await future).updateMessage(message, newMessage);

  Future<void> send(String message, {Message? replyTo}) async =>
      await room.sendTextEvent(
        message,
        inReplyTo: replyTo == null ? null : await room.getEventById(replyTo.id),
      );

  Future<chat.User> resolveUser(String id) async {
    final user = await room.client.getUserProfile(id);
    return chat.User(
      id: id,
      name: user.displayname,
      imageSource: (await user.avatarUrl?.getThumbnailUri(
        // TODO: Fix use of account avatar not room avatar
        room.client,
        width: 24,
        height: 24,
      ))?.toString(),
    );
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomChatController, ChatController, Room>(
        RoomChatController.new,
      );
}
