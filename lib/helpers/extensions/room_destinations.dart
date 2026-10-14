import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

extension RoomDestinations on IList<Room> {
  List<NavigationRailM3EDestination> toDestinations({required bool isDm}) =>
      map(
        (room) => NavigationRailM3EDestination(
          label: room.metadata?.name ?? "Unnamed Room",
          badgeCount: switch (room.metadata?.unreadNotifications) {
            0 || null => room.metadata?.unreadMessages == 0 ? null : 0,
            int unread => unread,
          },
          icon: AvatarOrHash(
            room.metadata?.avatar,
            room.metadata?.name ?? "Unnamed Room",
            fallback: isDm ? null : const Icon(Icons.numbers),
          ),
        ),
      ).toList();
}
