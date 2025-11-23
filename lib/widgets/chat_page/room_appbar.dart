import "package:flutter/material.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/models/full_room.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class RoomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final FullRoom room;
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
            room.avatar,
            room.title,
            height: 24,
            fallback: Icon(Icons.numbers),
            headers: room.roomData.client.headers,
          )
        : DrawerButton(onPressed: () => onOpenDrawer(context)),
    scrolledUnderElevation: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(room.title, overflow: TextOverflow.ellipsis),
        if (room.roomData.topic.isNotEmpty)
          Text(
            room.roomData.topic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    ),
    actions: [
      IconButton(
        onPressed: () => onOpenMemberList(context),
        icon: Icon(Icons.people),
      ),
    ],
  );
}
