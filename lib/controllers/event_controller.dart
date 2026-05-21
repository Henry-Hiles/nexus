import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_event_request.dart";

class EventController extends AsyncNotifier<Event?> {
  final GetEventRequest request;
  EventController(this.request);

  @override
  Future<Event?> build() async {
    final room = ref.watch(
      RoomsController.provider.select((value) => value[request.roomId]),
    );
    final event = room?.events.values.firstWhereOrNull(
      (event) => event.eventId == request.eventId,
    );

    return event ??
        await ref
            .watch(ClientController.provider.notifier)
            .getEvent(request)
            .onError((_, _) => null);
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<EventController, Event?, GetEventRequest>(
        EventController.new,
      );
}
