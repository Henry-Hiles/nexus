import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_chat_core/flutter_chat_core.dart" as chat;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart" as tagger;
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/new_events_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";
import "package:nexus/helpers/extensions/list_to_messages.dart";
import "package:nexus/models/relation_type.dart";

class RoomChatController extends AsyncNotifier<ChatController> {
  final String roomId;
  RoomChatController(this.roomId);

  @override
  Future<ChatController> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    final events =
        ref.read(SelectedRoomController.provider)?.events ??
        const IList.empty();

    ref.onDispose(
      ref.listen(NewEventsController.provider(roomId), (_, next) async {
        for (final event in next) {
          if (event.type == "m.room.redaction") {
            final controller = await future;
            final message = controller.messages.firstWhereOrNull(
              (message) => message.id == event.content["redacts"],
            );
            if (message == null) return;

            await controller.removeMessage(message);
          } else {
            final message = await event.toMessage(client, includeEdits: true);
            if (event.relationType == "m.replace") {
              final controller = await future;
              final oldMessage = controller.messages.firstWhereOrNull(
                (element) => element.id == event.relatesTo,
              );
              if (oldMessage == null || message == null) return;

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
            if (message != null) {
              return await insertMessage(message);
            }
          }
        }
      }).close,
    );

    final messages = await events.toMessages(client);
    return InMemoryChatController(messages: messages);
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
    // final controller = await future;
    // await controller.removeMessage(message);
    // await room.redactEvent(message.id, reason: reason);
  }

  Future<void> loadOlder() async {
    // final currentEvents = await future;
    // await ref.watch(EventsController.provider(room).notifier).prev();
    // final timeline = await ref.watch(EventsController.provider(room).future);

    // final controller = await future;
    // await controller.insertAllMessages(
    //   await timeline.events
    //       .where(
    //         (event) => !currentEvents.messages.any(
    //           (existingEvent) => existingEvent.id == event.eventId,
    //         ),
    //       )
    //       .toList()
    //       .toMessages(room, timeline),
    //   index: 0,
    // );
    // ref.notifyListeners();
  }

  Future<void> updateMessage(Message message, Message newMessage) async =>
      (await future).updateMessage(message, newMessage);

  Future<void> send(
    String message, {
    required Iterable<tagger.Tag> tags,
    required RelationType relationType,
    Message? relation,
  }) async {
    // var taggedMessage = message;

    // for (final tag in tags) {
    //   final escaped = RegExp.escape(tag.id);
    //   final pattern = RegExp(r"@+(" + escaped + r")(#[^#]*#)?");

    //   taggedMessage = taggedMessage.replaceAllMapped(
    //     pattern,
    //     (match) => match.group(1)!,
    //   );
    // }

    // await room.sendTextEvent(
    //   taggedMessage,
    //   editEventId: relationType == RelationType.edit ? relation?.id : null,
    //   inReplyTo: (relationType == RelationType.reply && relation != null)
    //       ? await room.getEventById(relation.id)
    //       : null,
    // );
  }

  Future<chat.User> resolveUser(String id) async {
    // final user = await room.client.getUserProfile(id);
    return chat.User(
      id: id,
      // name: user.displayname,
      // imageSource: user.avatarUrl == null
      //     ? null
      //     : (await ref.watch(
      //         AvatarController.provider(user.avatarUrl!.toString()).future,
      //       )).toString(),
    );
  }

  static final provider =
      AsyncNotifierProvider.family<RoomChatController, ChatController, String>(
        RoomChatController.new,
      );
}
