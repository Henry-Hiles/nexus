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

    ISet<String> collectChildIds(String spaceId) {
      ISet<String> result = ISet<String>();
      void walk(String currentId) {
        final children = spaceEdges[currentId] ?? IList<SpaceEdge>();
        for (final edge in children) {
          final childId = edge.childId;
          if (!result.contains(childId)) {
            result = result.add(childId);
            walk(childId);
          }
        }
      }

      walk(spaceId);
      return result;
    }

    final spaceIdToChildren = IMap.fromEntries(
      topLevelSpaceIds.map((spaceId) {
        final children = collectChildIds(
          spaceId,
        ).map((id) => rooms[id]).nonNulls.toIList();
        return MapEntry(spaceId, children);
      }),
    );

    final allNestedRoomIds = spaceIdToChildren.values
        .expand((l) => l)
        .map((r) => rooms.entries.firstWhere((e) => e.value == r).key)
        .toISet();

    final dmRooms = rooms.values
        .where((room) => room.metadata?.dmUserId != null)
        .toIList();

    final homeRooms = rooms.entries
        .where(
          (e) =>
              e.value.metadata?.dmUserId == null &&
              !allNestedRoomIds.contains(e.key) &&
              !topLevelSpaceIds.contains(e.key),
        )
        .map((e) => e.value)
        .toIList();

    final topLevelSpacesList = topLevelSpaceIds
        .map((id) {
          final room = rooms[id];
          if (room == null) return null;

          final children = spaceIdToChildren[id] ?? IList<Room>();
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
