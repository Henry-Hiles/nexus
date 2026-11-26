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
import "package:nexus/models/space_edge.dart";
import "package:nexus/models/subspace.dart";

class SpacesController extends AsyncNotifier<IList<Space>> {
  @override
  Future<IList<Space>> build() async {
    final rooms = ref.watch(RoomsController.provider);
    final topLevelSpaceIds = ref.watch(TopLevelSpacesController.provider);
    final spaceEdges = ref.watch(SpaceEdgesController.provider);
    final accountData = ref.watch(AccountDataController.provider);

    bool hasValidOrder(SpaceEdge edge) =>
        edge.order.isNotEmpty &&
        edge.order.length <= 50 &&
        edge.order.codeUnits.every((unit) => unit >= 0x20 && unit <= 0x7E);

    int compareEdges(SpaceEdge a, SpaceEdge b) =>
        switch ((hasValidOrder(a), hasValidOrder(b))) {
          (true, false) => -1,
          (false, true) => 1,
          (true, true) when a.order != b.order => a.order.compareTo(b.order),
          _ => switch (a.childEventRowId.compareTo(b.childEventRowId)) {
            0 => a.childId.compareTo(b.childId),
            final byRowId => byRowId,
          },
        };

    final childrenById = spaceEdges.map(
      (spaceId, edges) => .new(
        spaceId,
        edges.sort(compareEdges).map((edge) => edge.childId).toList(),
      ),
    );

    /// Everything under [spaceId], however deep, skipping any already
    /// [visited] so cycles end.
    ISet<String> collectDescendants(
      String spaceId, [
      ISet<String> visited = const .empty(),
    ]) => (childrenById[spaceId] ?? const []).fold(
      visited,
      (visited, childId) => visited.contains(childId)
          ? visited
          : collectDescendants(childId, visited.add(childId)),
    );

    Space buildSpace(String spaceId) {
      final space = rooms[spaceId];
      final directChildrenIds = childrenById[spaceId] ?? const [];

      return .new(
        id: spaceId,
        room: space,
        title: space?.metadata?.name ?? "Unnamed Space",
        children: .new(
          directChildrenIds
              .where((childId) => !childrenById.containsKey(childId))
              .map((childId) => rooms[childId])
              .nonNulls,
        ),
        subSpaces: .new(
          directChildrenIds
              .where(childrenById.containsKey)
              .map(
                (childId) => switch (rooms[childId]) {
                  final room? => Subspace(
                    room: room,
                    children: .new(
                      collectDescendants(childId)
                          .where((id) => !childrenById.containsKey(id))
                          .map((id) => rooms[id])
                          .nonNulls,
                    ),
                  ),
                  null => null,
                },
              )
              .nonNulls,
        ),
        childrenIndex: directChildrenIds
            .where(rooms.containsKey)
            .takeWhile(childrenById.containsKey)
            .length,
      );
    }

    final spaces = topLevelSpaceIds
        .where(rooms.containsKey)
        .map(buildSpace)
        .toIList();

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

    int priority(Room room) => switch ((roomOrder, room.metadata)) {
      (.recentActivity || .spaceOrder, _) => 0,
      (_, RoomMetadata(unreadHighlights: > 0)) => 0,
      (.mentionedFirst, _) => 1,
      (.unreadFirst, RoomMetadata(unreadNotifications: > 0)) ||
      (.unreadFirst, RoomMetadata(unreadMessages: > 0)) => 1,
      (.unreadFirst, _) => 2,
    };
    DateTime activity(Room room) => room.metadata?.sortingTimestamp ?? .new(0);

    // Higher priority first, then most recent activity first
    IList<Room> sortRooms(IList<Room> rooms) => rooms.sort(
      (a, b) => switch (priority(a).compareTo(priority(b))) {
        0 => activity(b).compareTo(activity(a)),
        final byPriority => byPriority,
      },
    );

    IList<Room> orderRooms(Space space, IList<Room> rooms) =>
        roomOrder == .spaceOrder && space.room != null
        ? rooms
        : sortRooms(rooms);

    return .new(
      allSpaces.map(
        (space) => space.copyWith(
          children: orderRooms(space, space.children),
          subSpaces: .new(
            space.subSpaces.map(
              (subspace) => subspace.copyWith(
                children: orderRooms(space, subspace.children),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static final provider = AsyncNotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
