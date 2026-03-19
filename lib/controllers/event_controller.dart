import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_event_request.dart";

class EventController extends AsyncNotifier<Event?> {
  final GetEventRequest request;
  EventController(this.request);

  @override
  Future<Event?> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    return await client.getEvent(request).onError((_, _) => null);
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<EventController, Event?, GetEventRequest>(
        EventController.new,
      );
}
