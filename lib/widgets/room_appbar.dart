import "dart:io";

import "package:flutter/material.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/models/full_room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class RoomAppbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final FullRoom room;
  final VoidCallback onOpenMemberList;
  final VoidCallback onOpenDrawer;
  const RoomAppbar(
    this.room, {
    required this.isDesktop,
    required this.onOpenMemberList,
    required this.onOpenDrawer,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height + 16);

  @override
  AppBar build(BuildContext context) => AppBar(
    bottom: PreferredSize(
      preferredSize: Size.zero, // Does this even matter??
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8).copyWith(top: 0),
              child: Text(
                room.roomData.topic,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    leading: isDesktop ? null : DrawerButton(onPressed: onOpenDrawer),
    actionsPadding: EdgeInsets.symmetric(horizontal: 8),
    title: Row(
      children: [
        AvatarOrHash(
          room.avatar,
          room.title,
          fallback: Icon(Icons.numbers),
          headers: room.roomData.client.headers,
        ),
        SizedBox(width: 12),
        Expanded(child: Text(room.title, overflow: TextOverflow.ellipsis)),
      ],
    ),
    actions: [
      IconButton(onPressed: onOpenMemberList, icon: Icon(Icons.people)),
      if (!(Platform.isAndroid || Platform.isIOS))
        IconButton(onPressed: () => exit(0), icon: Icon(Icons.close)),
    ],
  );
}
