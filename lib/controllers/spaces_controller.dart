import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/top_level_spaces_controller.dart";
import "package:nexus/models/space.dart";

class SpacesController extends AsyncNotifier<IList<Space>> {
  @override
  Future<IList<Space>> build() async {
    final topLevelSpaceIds = ref.watch(TopLevelSpacesController.provider);
    final rooms = ref.watch(RoomsController.provider);

    final topLevelSpaces = topLevelSpaceIds
        .map((id) => rooms[id])
        .nonNulls
        .toIList();

    final dmRooms = rooms.values
        .where((room) => room.metadata?.dmUserId != null)
        .toIList();

    final topLevelRooms = rooms.values
        .where((room) => room.metadata?.dmUserId == null)
        .where(
          (room) => spaceRooms.every(
            (space) =>
                space.spaceChildren.every((child) => child.roomId != room.id),
          ),
        )
        .toIList();

    // 4️⃣ Combine all into a single IList
    return IList([
      Space(
        id: "home",
        title: "Home",
        children: topLevelRooms,
        icon: Icons.home,
      ),
      Space(
        id: "dms",
        title: "Direct Messages",
        children: dmRooms,
        icon: Icons.person,
      ),
      ...topLevelSpaces,
    ]);
  }

  static final provider = AsyncNotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
