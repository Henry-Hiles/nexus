import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/events_controller.dart";
import "package:nexus/helpers/extension_helper.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  final Room room;
  RoomChatController(this.room);

  @override
  Future<ChatController> build() async {
    final response = await ref.watch(EventsController.provider(room).future);

    ref.onDispose(
      room.client.onTimelineEvent.stream.listen((event) async {
        if (event.roomId != room.id) return;
        final message = await event.toMessage();
        if (message != null) {
          await insertMessage(message);
        }
      }).cancel,
    );

    return InMemoryChatController(
      messages: (await Future.wait(
        response.chunk.map(
          (event) => Event.fromMatrixEvent(event, room).toMessage(),
        ),
      )).nonNulls.toList().reversed.toList(),
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

  Future<void> loadOlder() async {
    final controller = await future;
    final response = await ref
        .watch(EventsController.provider(room).notifier)
        .prev();
    await controller.insertAllMessages(
      (await Future.wait(
        response.chunk.map(
          (event) => Event.fromMatrixEvent(event, room).toMessage(),
        ),
      )).nonNulls.toList().reversed.toList(),
      index: 0,
    );
  }

  Future<void> markRead() async {
    final controller = await future;
    await room.setReadMarker(controller.messages.last.id);
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
