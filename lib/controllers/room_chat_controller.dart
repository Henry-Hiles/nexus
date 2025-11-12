import "package:collection/collection.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  RoomChatController(this.room);
  final Room room;

  @override
  Future<ChatController> build() async {
    final timeline = await room.getTimeline();
    room.client.onTimelineEvent.stream.listen((event) async {
      if (event.roomId != room.id) return;
      final message = await toMessage(event);
      if (message != null) {
        await insertMessage(message);
      }
    });

    return InMemoryChatController(
      messages: (await Future.wait(
        timeline.events.map(toMessage),
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

  Future<Message?> toMessage(Event event) async {
    final replyId = event.relationshipType == RelationshipTypes.reply
        ? event.relationshipEventId
        : null;
    final metadata = {
      "eventType": event.type,
      "displayName": event.senderFromMemoryOrFallback.displayName,
      "txnId": event.transactionId,
    };
    return event.redacted
        ? Message.text(
            metadata: metadata,
            id: event.eventId,
            authorId: event.senderId,
            text: "~~This message has been redacted.~~",
            deletedAt: event.redactedBecause?.originServerTs,
          )
        : switch (event.type) {
            EventTypes.Message => switch (event.messageType) {
              MessageTypes.Image => Message.image(
                metadata: metadata,
                id: event.eventId,
                authorId: event.senderId,
                source: (await event.getAttachmentUri()).toString(),
                replyToMessageId: replyId,
                deliveredAt: event.originServerTs,
              ),
              MessageTypes.Audio => Message.audio(
                metadata: metadata,
                id: event.eventId,
                authorId: event.senderId,
                text: event.body,
                replyToMessageId: replyId,
                source: (await event.getAttachmentUri()).toString(),
                deliveredAt: event.originServerTs,
                duration: Duration(hours: 1),
              ),
              MessageTypes.File => Message.file(
                name: event.content["filename"].toString(),
                metadata: metadata,
                id: event.eventId,
                authorId: event.senderId,
                source: (await event.getAttachmentUri()).toString(),
                replyToMessageId: replyId,
                deliveredAt: event.originServerTs,
              ),
              _ => Message.text(
                metadata: metadata,
                id: event.eventId,
                authorId: event.senderId,
                text: event.body,
                replyToMessageId: replyId,
                deliveredAt: event.originServerTs,
              ),
            },
            EventTypes.RoomMember => Message.system(
              metadata: metadata,
              id: event.eventId,
              authorId: event.senderId,
              text:
                  "${event.senderFromMemoryOrFallback.calcDisplayname()} joined the room.",
            ),
            EventTypes.Redaction => null,
            _ => Message.unsupported(
              metadata: metadata,
              id: event.eventId,
              authorId: event.senderId,
              replyToMessageId: replyId,
            ),
          };
  }

  Future<void> send(String message) async {
    await room.sendTextEvent(message);
  }

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
