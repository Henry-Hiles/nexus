import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class EventsController extends AsyncNotifier<Timeline> {
  EventsController(this.room);
  final Room room;

  @override
  Future<Timeline> build({String? from}) => room.getTimeline();

  Future<void> prev() async {
    final timeline = await future;
    await timeline.requestHistory();
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<EventsController, Timeline, Room>(EventsController.new);
}
