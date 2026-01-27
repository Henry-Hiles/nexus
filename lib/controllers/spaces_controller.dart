import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/top_level_spaces_controller.dart";
import "package:nexus/controllers/space_edges_controller.dart";
import "package:nexus/models/space.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space_edge.dart";

class SpacesController extends Notifier<IList<Space>> {
  @override
  IList<Space> build() {
    final rooms = ref.watch(RoomsController.provider);
    final topLevelSpaceIds = ref.watch(TopLevelSpacesController.provider);
    final spaceEdges = ref.watch(SpaceEdgesController.provider);

    final childRoomsBySpaceId = IMap.fromEntries(
      topLevelSpaceIds.map((spaceId) {
        ISet<String> walk(String currentId) {
          final children = spaceEdges[currentId] ?? IList<SpaceEdge>();

          return children.fold<ISet<String>>(const ISet.empty(), (acc, edge) {
            final childId = edge.childId;
            final isSpace = spaceEdges.containsKey(childId);

            return acc
                .addAll(!isSpace ? ISet([childId]) : const ISet.empty())
                .addAll(isSpace ? walk(childId) : const ISet.empty());
          });
        }

        return MapEntry(
          spaceId,
          walk(spaceId).map((id) => rooms[id]).nonNulls.toIList(),
        );
      }),
    );

    final allNestedRoomIds = childRoomsBySpaceId.values
        .expand((l) => l)
        .map(
          (room) =>
              rooms.entries.firstWhere((entry) => entry.value == room).key,
        )
        .toISet();

    final dmRooms = rooms.values
        .where((room) => room.metadata?.dmUserId != null)
        .toIList();

    final homeRooms = rooms.entries
        .where(
          (e) =>
              e.value.metadata?.dmUserId == null &&
              !allNestedRoomIds.contains(e.key) &&
              !topLevelSpaceIds.contains(e.key) &&
              !spaceEdges.containsKey(e.key),
        )
        .map((e) => e.value)
        .toIList();

    final topLevelSpacesList = topLevelSpaceIds
        .map((id) {
          final room = rooms[id];
          if (room == null) return null;

          final children = childRoomsBySpaceId[id] ?? IList<Room>();
          return Space(
            id: id,
            title: room.metadata?.name ?? "Unnamed Room",
            room: room,
            children: children,
          );
        })
        .nonNulls
        .toIList();

    return <Space>[
      Space(id: "home", title: "Home", icon: Icons.home, children: homeRooms),
      Space(
        id: "dms",
        title: "Direct Messages",
        icon: Icons.people,
        children: dmRooms,
      ),
      ...topLevelSpacesList,
    ].toIList();
  }

  static final provider = NotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
