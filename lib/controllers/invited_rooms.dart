import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/invited_room.dart";

class InvitedRoomsController extends Notifier<IList<InvitedRoom>> {
  @override
  IList<InvitedRoom> build() => .new();

  void set(IList<InvitedRoom> newState) => state = newState;

  static final provider =
      NotifierProvider<InvitedRoomsController, IList<InvitedRoom>>(
        InvitedRoomsController.new,
      );
}
