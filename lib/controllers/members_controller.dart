import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/requests/get_room_state_request.dart";
import "package:nexus/models/room.dart";

class MembersController extends AsyncNotifier<IList<Membership>> {
  final Room room;
  MembersController(this.room);

  @override
  Future<IList<Membership>> build() async {
    if (room.metadata == null) return const IList.empty();

    final state = await ref
        .watch(ClientController.provider.notifier)
        .getRoomState(
          GetRoomStateRequest(
            roomId: room.metadata!.id,
            fetchMembers: room.metadata!.hasMemberList == false,
            includeMembers: true,
          ),
        );

    return state.nonNulls
        .where((member) => member.content["membership"] == "join")
        .map(
          (membership) => Membership.fromContent(
            membership.content,
            membership.stateKey!,
            ref.watch(
                  ClientStateController.provider.select(
                    (value) => value?.homeserverUrl,
                  ),
                ) ??
                "",
          ),
        )
        .toIList();
  }

  static final provider =
      AsyncNotifierProvider.family<MembersController, IList<Membership>, Room>(
        MembersController.new,
      );
}
