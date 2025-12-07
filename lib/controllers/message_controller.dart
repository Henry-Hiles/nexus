import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";

class MessageController extends AsyncNotifier<TextMessage?> {
  final String id;
  MessageController(this.id);

  @override
  Future<TextMessage?> build() async {
    final room = await ref.watch(SelectedRoomController.provider.future);
    if (room == null) return null;

    final event = await room.roomData.getEventById(id);
    return (await event?.toMessage(mustBeText: true)) as TextMessage?;
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MessageController, TextMessage?, String>(
        MessageController.new,
      );
}
