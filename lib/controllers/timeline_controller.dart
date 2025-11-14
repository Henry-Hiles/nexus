import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class TimelineController extends AsyncNotifier<Timeline> {
  TimelineController(this.room);
  final Room room;

  @override
  Future<Timeline> build() => room.getTimeline();

  Future<void> prev() async {
    final timeline = await future;
    await timeline.requestHistory();
    state = AsyncValue.data(timeline);
  }

  static final provider =
      AsyncNotifierProvider.family<TimelineController, Timeline, Room>(
        TimelineController.new,
      );
}
