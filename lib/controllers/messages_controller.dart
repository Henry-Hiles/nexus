import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/models/message_config.dart";
import "package:nexus/models/messages_config.dart";

class MessagesController extends AsyncNotifier<IList<Message>> {
  final MessagesConfig config;
  MessagesController(this.config);

  @override
  Future<IList<Message>> build() async => (await Future.wait(
    config.events.map(
      (event) => ref.watch(
        MessageController.provider(
          MessageConfig(event: event, room: config.room),
        ).future,
      ),
    ),
  )).nonNulls.toIList();

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MessagesController, IList<Message>, MessagesConfig>(
        MessagesController.new,
      );
}
