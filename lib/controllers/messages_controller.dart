import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/message_config.dart";

class MessagesController extends AsyncNotifier<IList<Message>> {
  final IList<Event> events;
  MessagesController(this.events);

  @override
  Future<IList<Message>> build() async => (await Future.wait(
    events.map(
      (event) => ref.watch(
        MessageController.provider(MessageConfig(event: event)).future,
      ),
    ),
  )).nonNulls.toIList();

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MessagesController, IList<Message>, IList<Event>>(
        MessagesController.new,
      );
}
