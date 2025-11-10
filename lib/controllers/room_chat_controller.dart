import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class RoomChatController extends Notifier<ChatController> {
  RoomChatController(this.id);
  final String id;

  @override
  InMemoryChatController build() => InMemoryChatController(
    messages: [
      Message.text(id: "foo2", authorId: "foo", text: "**Some** text"),
      Message.text(
        id: "foo3",
        authorId: "foo5",
        text: "Some text 2 https://federated.nexus",
      ),
      Message.text(
        id: "aksdjflkasdjf",
        authorId: "foo",
        text: "Some text 2 https://github.com/Henry-hiles/nixos",
      ),
      Message.system(id: "foo4", authorId: "", text: "system"),
      Message.text(id: "foo6", authorId: "foo5", text: "Some text 2"),
      Message.image(
        id: "foo5",
        authorId: "foobar3",
        source:
            "https://henryhiles.com/_astro/federatedNexus.BvZmkdyc_2b28Im.webp",
      ),
      Message.text(id: "foo7", authorId: "foobar3", text: "this has an image"),
    ],
  );

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
