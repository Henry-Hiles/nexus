import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/pinned_events.dart";

class PinnedIdsController extends Notifier<IList<String>> {
  final String roomId;
  PinnedIdsController(this.roomId);

  @override
  IList<String> build() {
    final room = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]),
    );

    if (room == null) return .new();

    final pinnedRowId = room.state[EventType.pinnedEvents.type]?[""];
    final pinnedStateEvent = pinnedRowId == null
        ? null
        : room.events[pinnedRowId];

    if (pinnedStateEvent?.content case PinnedEventsContent content) {
      return content.pinnedEvents;
    }

    return .new();
  }

  Future<void> addPin(String eventId) async =>
      setPinned(.new(pinnedEvents: .new(state.add(eventId))));

  Future<void> removePin(String eventId) async =>
      setPinned(.new(pinnedEvents: .new(state.remove(eventId))));

  Future<void> setPinned(PinnedEventsContent content) => ref
      .read(ClientController.provider.notifier)
      .setState(
        .new(
          roomId: roomId,
          type: EventType.pinnedEvents.type,
          stateKey: "",
          content: content,
        ),
      );

  static final provider = NotifierProvider.family
      .autoDispose<PinnedIdsController, IList<String>, String>(
        PinnedIdsController.new,
      );
}
