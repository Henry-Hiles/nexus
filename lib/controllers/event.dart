import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_event.dart";

class EventController(final GetEventRequest request)
    extends AsyncNotifier<Event?> {
  @override
  Future<Event?> build() async {
    final event = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms[request.roomId]?.events.values.firstWhereOrNull(
          (event) => event.eventId == request.eventId,
        ),
      ),
    );

    if (event != null) return event;

    final link = ref.keepAlive();
    final fetchedEvent = await ref
        .read(ClientController.provider.notifier)
        .getEvent(request)
        .onError((_, _) => null)
        .whenComplete(link.close);

    if (fetchedEvent != null) {
      // Storing the event invalidates this provider, as it watches the room.
      // If nothing is listening, Riverpod won't rebuild it, and this build's
      // result would be lost, so store it after returning.
      final rooms = ref.read(RoomsController.provider.notifier);
      Future.microtask(
        () => rooms.update(
          .new({
            request.roomId: .new(
              events: .new({fetchedEvent.rowId: fetchedEvent}),
            ),
          }),
        ),
      );
    }

    return fetchedEvent;
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<EventController, Event?, GetEventRequest>(
        EventController.new,
      );
}
