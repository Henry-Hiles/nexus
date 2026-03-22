import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/requests/get_room_state_request.dart";
import "package:nexus/models/room.dart";

class MembersController extends Notifier<IList<Membership>> {
  final Room room;
  MembersController(this.room);

  @override
  IList<Membership> build() {
    IList<Membership> membersFromState(IList<Event> members) => members.nonNulls
        .where((member) => member.content["membership"] == "join")
        .map(
          (membership) =>
              Membership.fromContent(membership.content, membership.stateKey!),
        )
        .toIList();

    if (room.metadata != null) {
      ref
          .watch(ClientController.provider.notifier)
          .getRoomState(
            GetRoomStateRequest(
              roomId: room.metadata!.id,
              fetchMembers: room.metadata!.hasMemberList == false,
              includeMembers: true,
            ),
          )
          .then((value) => state = membersFromState(value));
    }

    return membersFromState(
      (room.state["m.room.members"]?.values ?? [])
          .map(
            (eventRowId) => room.events.firstWhereOrNull(
              (event) => event.rowId == eventRowId,
            ),
          )
          .nonNulls
          .toIList(),
    );
  }

  static final provider =
      NotifierProvider.family<MembersController, IList<Membership>, Room>(
        MembersController.new,
      );
}
