import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/account_data_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/top_level_spaces_controller.dart";
import "package:nexus/controllers/space_edges_controller.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space.dart";
import "package:nexus/models/subspace.dart";

class SpacesController extends Notifier<IList<Space>> {
  @override
  IList<Space> build() {
    final rooms = ref.watch(RoomsController.provider);
    final topLevelSpaceIds = ref.watch(TopLevelSpacesController.provider);
    final spaceEdges = ref.watch(SpaceEdgesController.provider);
    final accountData = ref.watch(AccountDataController.provider);

    final childrenById = {
      for (final entry in spaceEdges.entries)
        entry.key: entry.value.map((e) => e.childId).toList(),
    };

    Set<String> collectDescendants(String startId) {
      final visited = <String>{};
      final stack = [startId];

      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        final children = childrenById[current] ?? const [];

        for (final child in children) {
          if (visited.add(child)) {
            stack.add(child);
          }
        }
      }

      return visited;
    }

    Space buildSpace(String spaceId) {
      final space = rooms[spaceId];
      final directChildrenIds = childrenById[spaceId] ?? const [];

      final directRooms = <Room>[];
      final subSpaces = <Subspace>[];

      for (final childId in directChildrenIds) {
        final room = rooms[childId];
        if (room == null) continue;

        if (childrenById.containsKey(childId)) {
          final descendants = collectDescendants(childId);

          subSpaces.add(
            .new(
              room: room,
              children: .new(descendants.map((id) => rooms[id]).nonNulls),
            ),
          );
        } else {
          directRooms.add(room);
        }
      }

      return .new(
        id: spaceId,
        room: space,
        title: space?.metadata?.name ?? "Unnamed Space",
        children: .new(directRooms),
        subSpaces: .new(subSpaces),
      );
    }

    final spaces = topLevelSpaceIds.map(buildSpace).toIList();

    final usedRoomIds = {
      for (final space in spaces) ...[
        ...space.children.map((r) => r.metadata?.id),
        ...space.subSpaces.expand((s) => s.children.map((r) => r.metadata?.id)),
      ],
    }.nonNulls.toISet();

    final directMessages = IMap(
      accountData["m.direct"]?.content ?? {},
    ).values.expand((e) => e).toISet();

    final otherRooms = rooms.entries
        .where(
          (e) =>
              !usedRoomIds.contains(e.key) &&
              !topLevelSpaceIds.contains(e.key) &&
              !childrenById.containsKey(e.key),
        )
        .map((e) => e.value)
        .toIList();

    final homeRooms = otherRooms
        .where((r) => !directMessages.contains(r.metadata?.id))
        .toIList();

    final dmRooms = otherRooms
        .where((r) => directMessages.contains(r.metadata?.id))
        .toIList();

    final allSpaces = <Space>[
      .new(
        id: "home",
        title: "Home",
        icon: Icons.home,
        children: homeRooms,
        subSpaces: .new(),
      ),
      .new(
        id: "dms",
        title: "Direct Messages",
        icon: Icons.people,
        children: dmRooms,
        subSpaces: .new(),
      ),
      ...spaces,
    ];

    return allSpaces
        .map(
          (space) => space.copyWith(
            children: .new(
              space.children
                  .sortedBy(
                    (element) =>
                        element
                            .metadata
                            ?.sortingTimestamp
                            .millisecondsSinceEpoch ??
                        0,
                  )
                  .sortedBy((room) => room.metadata?.unreadMessages ?? 0)
                  .reversed,
            ),
          ),
        )
        .toIList();
  }

  static final provider = NotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
