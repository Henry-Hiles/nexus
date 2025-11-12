import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/current_room_controller.dart";
import "package:nexus/helpers/extension_helper.dart";

class MessageController extends AsyncNotifier<TextMessage?> {
  final String id;
  MessageController(this.id);

  @override
  Future<TextMessage?> build() async {
    final room = await ref.watch(CurrentRoomController.provider.future);
    final event = await room.roomData.getEventById(id);
    return (await event?.toMessage(mustBeText: true)) as TextMessage;
  }

  static final provider =
      AsyncNotifierProvider.family<MessageController, TextMessage?, String>(
        MessageController.new,
      );
}
