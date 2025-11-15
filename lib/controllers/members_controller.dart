import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class MembersController extends AsyncNotifier<IList<MatrixEvent>> {
  final Room room;
  MembersController(this.room);

  @override
  Future<IList<MatrixEvent>> build() async => IList(
    (await room.client.getMembersByRoom(
          room.id,
          notMembership: Membership.leave,
        )) ??
        [],
  );

  static final provider =
      AsyncNotifierProvider.family<MembersController, IList<MatrixEvent>, Room>(
        MembersController.new,
      );
}
