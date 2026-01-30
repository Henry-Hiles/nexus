import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/room_menu.dart";

class RoomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final Room room;
  final void Function(BuildContext context) onOpenMemberList;
  final void Function(BuildContext context) onOpenDrawer;
  const RoomAppbar(
    this.room, {
    required this.isDesktop,
    required this.onOpenMemberList,
    required this.onOpenDrawer,
    super.key,
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) => Appbar(
    leading: isDesktop
        ? AvatarOrHash(
            room.metadata?.avatar,
            room.metadata?.name ?? "Unnamed Rooms",
            height: 24,
            fallback: Icon(Icons.numbers),
          )
        : DrawerButton(onPressed: () => onOpenDrawer(context)),
    scrolledUnderElevation: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.metadata?.name ?? "Unnamed Room",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (room.metadata?.topic?.isNotEmpty == true)
          Text(
            room.metadata!.topic!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
    actions: [
      IconButton(onPressed: () {}, icon: Icon(Icons.push_pin)),
      IconButton(
        onPressed: () => onOpenMemberList(context),
        icon: Icon(Icons.people),
      ),
      RoomMenu(room),
    ].toIList(),
  );
}
