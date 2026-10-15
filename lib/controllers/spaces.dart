import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/top_level_spaces.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/room_metadata.dart";
import "package:nexus/models/space.dart";
import "package:nexus/models/subspace.dart";

class SpacesController extends AsyncNotifier<IList<Space>> {
  @override
  Future<IList<Space>> build() async {
    final rooms = ref.watch(RoomsController.provider);
    final topLevelSpaceIds = ref.watch(TopLevelSpacesController.provider);
    final spaceEdges = ref.watch(SpaceEdgesController.provider);
    final accountData = ref.watch(AccountDataController.provider);

    final childrenById = spaceEdges.map(
      (spaceId, edges) =>
          MapEntry(spaceId, edges.map((edge) => edge.childId).toList()),
    );

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

    final usedRooms = spaces
        .expand(
          (space) => [
            ...space.children,
            ...space.subSpaces.expand((s) => s.children),
          ],
        )
        .toISet();
    final usedRoomIds = usedRooms.map((room) => room.metadata?.id).toSet();

    final directMessages = accountData.directMessages.values.flattened.toSet();

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
        .addAll(
          await ref.watch(
                SettingsController.provider.selectAsync(
                  (data) => data.showAllInHome,
                ),
              )
              ? usedRooms
              : .empty(),
        )
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

    final roomOrder = await ref.watch(
      SettingsController.provider.selectAsync((data) => data.roomOrder),
    );

    // Mentioned -> Unread -> Other
    int unreadPriority(Room room) => switch (room.metadata) {
      RoomMetadata(unreadHighlights: > 0) => 0,
      RoomMetadata(unreadNotifications: > 0) ||
      RoomMetadata(unreadMessages: > 0) => 1,
      _ => 2,
    };

    return allSpaces
        .map(
          (space) => space.copyWith(
            children: space.children.sort((a, b) {
              if (roomOrder == .unreadFirst) {
                final byUnread = unreadPriority(a).compareTo(unreadPriority(b));
                if (byUnread != 0) return byUnread;
              }

              // Most recent activity first
              return (b.metadata?.sortingTimestamp ?? DateTime(0)).compareTo(
                a.metadata?.sortingTimestamp ?? DateTime(0),
              );
            }),
          ),
        )
        .toIList();
  }

  static final provider = AsyncNotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
