import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/requests/join_room.dart";
import "package:nexus/models/room_summary.dart";

class RoomSummaryController extends AsyncNotifier<RoomSummary> {
  final JoinRoomRequest request;
  RoomSummaryController(this.request);

  @override
  Future<RoomSummary> build() =>
      ref.watch(ClientController.provider.notifier).getRoomSummary(request);

  static final provider = AsyncNotifierProvider.family
      .autoDispose<RoomSummaryController, RoomSummary, JoinRoomRequest>(
        RoomSummaryController.new,
      );
}
