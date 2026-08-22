import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/pinned_ids.dart";
import "package:nexus/models/event.dart";

class PinnedEventsController(final String roomId)
    extends AsyncNotifier<IList<Event>> {
  @override
  Future<IList<Event>> build() async {
    final pinIds = ref.watch(PinnedIdsController.provider(roomId));

    return (await Future.wait(
      pinIds.map(
        (eventId) => ref.watch(
          EventController.provider(.new(eventId: eventId, roomId: roomId))
              .future,
        ),
      ),
    )).nonNulls.toIList();
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<PinnedEventsController, IList<Event>, String>(
        PinnedEventsController.new,
      );
}
