import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";

class MembersController extends AsyncNotifier<List<MatrixEvent>> {
  final Room room;
  MembersController(this.room);

  @override
  Future<List<MatrixEvent>> build() async =>
      (await room.client.getMembersByRoom(
        room.id,
        notMembership: Membership.leave,
      )) ??
      [];

  static final provider =
      AsyncNotifierProvider.family<MembersController, List<MatrixEvent>, Room>(
        MembersController.new,
      );
}
