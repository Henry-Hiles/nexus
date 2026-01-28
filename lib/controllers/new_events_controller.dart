import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/event.dart";

class NewEventsController extends Notifier<IList<Event>> {
  final String roomId;
  NewEventsController(this.roomId);

  @override
  IList<Event> build() => const IList.empty();

  void add(IList<Event> newEvents) => state = newEvents;

  static final provider = NotifierProvider.autoDispose
      .family<NewEventsController, IList<Event>, String>(
        NewEventsController.new,
      );
}
