import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_room_state_request.dart";

class MembersController extends AsyncNotifier<ISet<Event>> {
  final String roomId;
  MembersController(this.roomId);

  @override
  Future<ISet<Event>> build() async {
    final room = ref.watch(
      RoomsController.provider.select((value) => value[roomId]),
    );

    if (room == null) return const ISet.empty();

    if (!room.hasFetchedMembers) {
      final fetchedState = await ref
          .watch(ClientController.provider.notifier)
          .getRoomState(
            GetRoomStateRequest(
              roomId: roomId,
              fetchMembers: room.metadata?.hasMemberList ?? true,
              includeMembers: true,
            ),
          );

      await ref
          .read(RoomsController.provider.notifier)
          .addState(roomId, fetchedState, isMembers: true);
    }

    return room.state[EventType.membership.type]?.values
            .map((rowId) => room.events[rowId])
            .nonNulls
            .toISet() ??
        const ISet.empty();
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<MembersController, ISet<Event>, String>(MembersController.new);
}
