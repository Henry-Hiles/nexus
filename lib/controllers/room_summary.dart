import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/requests/join_room.dart";
import "package:nexus/models/room_summary.dart";

class RoomSummaryController(final JoinRoomRequest request)
    extends AsyncNotifier<RoomSummary> {
  @override
  Future<RoomSummary> build() =>
      ref.watch(ClientController.provider.notifier).getRoomSummary(request);

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomSummaryController, RoomSummary, JoinRoomRequest>(
        RoomSummaryController.new,
      );
}
