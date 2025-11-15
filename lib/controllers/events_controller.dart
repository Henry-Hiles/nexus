import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/from_controller.dart";

class EventsController extends AsyncNotifier<GetRoomEventsResponse> {
  EventsController(this.room);
  final Room room;

  @override
  Future<GetRoomEventsResponse> build({String? from}) async {
    final response = await room.client.getRoomEvents(
      room.id,
      Direction.b,
      from: from,
      limit: 32,
    );
    ref.watch(FromController.provider(room).notifier).set(response.end);
    return response;
  }

  Future<GetRoomEventsResponse> prev() async {
    final resp = await build(from: ref.read(FromController.provider(room)));
    return resp;
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<EventsController, GetRoomEventsResponse, Room>(
        EventsController.new,
      );
}
