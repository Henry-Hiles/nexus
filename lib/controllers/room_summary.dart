import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/requests/get_room_summary.dart";
import "package:nexus/models/room_summary.dart";

class RoomSummaryController(final GetRoomSummary request)
    extends AsyncNotifier<RoomSummary> {
  @override
  Future<RoomSummary> build() =>
      ref.read(ClientController.provider.notifier).getRoomSummary(request);

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomSummaryController, RoomSummary, GetRoomSummary>(
        RoomSummaryController.new,
      );
}
