import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

extension RoomDestination on Room {
  NavigationRailM3EDestination toDestination({
    required bool isDm,
    String? label,
    Widget? icon,
  }) => NavigationRailM3EDestination(
    label: label ?? metadata?.name ?? "Unnamed Room",
    badgeCount: switch (metadata?.unreadNotifications) {
      0 || null => metadata?.unreadMessages == 0 ? null : 0,
      int unread => unread,
    },
    icon:
        icon ??
        AvatarOrHash(
          metadata?.avatar,
          metadata?.name ?? "Unnamed Room",
          fallback: isDm ? null : const Icon(Icons.numbers),
        ),
  );
}

extension RoomDestinations on IList<Room> {
  List<NavigationRailM3EDestination> toDestinations({required bool isDm}) =>
      map((room) => room.toDestination(isDm: isDm)).toList();
}
