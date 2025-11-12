import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/helpers/extension_helper.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  RoomChatController(this.room);
  final Room room;

  @override
  Future<ChatController> build() async {
    final timeline = await room.getTimeline();
    room.client.onTimelineEvent.stream.listen((event) async {
      if (event.roomId != room.id) return;
      final message = await event.toMessage();
      if (message != null) {
        await insertMessage(message);
      }
    });

    return InMemoryChatController(
      messages: (await Future.wait(
        timeline.events.map((event) => event.toMessage()),
      )).toList().reversed.nonNulls.toList(),
    );
  }

  Future<void> insertMessage(Message message) async {
    final controller = await future;
    final oldMessage = controller.messages.firstWhereOrNull(
      (element) => element.metadata?["txnId"] == message.metadata?["txnId"],
    );

    return oldMessage == null
        ? controller.insertMessage(message)
        : controller.updateMessage(oldMessage, message);
  }

  Future<void> updateMessage(Message message, Message newMessage) async {
    final controller = await future;
    return controller.updateMessage(message, newMessage);
  }

  Future<void> send(String message, {String? replyTo}) async =>
      await room.sendTextEvent(
        message,
        inReplyTo: replyTo == null ? null : await room.getEventById(replyTo),
      );

  Future<chat.User> resolveUser(String id) async {
    final user = await room.client.getUserProfile(id);
    return chat.User(
      id: id,
      name: user.displayname,
      imageSource: (await user.avatarUrl?.getThumbnailUri(
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
