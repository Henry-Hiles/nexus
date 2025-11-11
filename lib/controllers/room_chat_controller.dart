import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class RoomChatController extends Notifier<ChatController> {
  RoomChatController(this.roomId);
  final String roomId;

  @override
  InMemoryChatController build() => InMemoryChatController();

  // void setRoom(Room room) => state = (await ref.watch(ClientController.provider.future));

  void send(String message) {
    state.insertMessage(
      Message.text(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: "foo",
        text: message,
      ),
    );
  }

  static final provider =
      NotifierProvider.family<RoomChatController, ChatController, String>(
        RoomChatController.new,
      );
}
