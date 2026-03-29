import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/requests/get_room_state_request.dart";

class MembersController extends AsyncNotifier<IList<Membership>> {
  @override
  Future<IList<Membership>> build() async {
    final data = ref.watch(
      SelectedRoomController.provider.select(
        (value) => value?.metadata == null
            ? null
            : (value!.metadata!.id, value.metadata!.hasMemberList),
      ),
    );
    if (data == null) return const IList.empty();

    final state = await ref
        .watch(ClientController.provider.notifier)
        .getRoomState(
          GetRoomStateRequest(
            roomId: data.$1,
            fetchMembers: data.$2 == false,
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
      AsyncNotifierProvider<MembersController, IList<Membership>>(
        MembersController.new,
      );
}
