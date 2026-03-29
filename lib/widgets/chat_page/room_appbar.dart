import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/expandable_image.dart";
import "package:nexus/widgets/chat_page/room_menu.dart";

class RoomAppbar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final void Function(BuildContext context) onOpenMemberList;
  final void Function(BuildContext context) onOpenDrawer;
  const RoomAppbar({
    required this.isDesktop,
    required this.onOpenMemberList,
    required this.onOpenDrawer,
    super.key,
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(SelectedRoomController.provider)!;
    return Appbar(
      leading: isDesktop
          ? ExpandableImage(
              room.metadata?.avatar?.toString(),
              child: AvatarOrHash(
                room.metadata?.avatar,
                room.metadata?.name ?? "Unnamed Rooms",
                height: 24,
                fallback: Icon(Icons.numbers),
              ),
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
        IconButton(
          onPressed: null,
          icon: Icon(Icons.push_pin),
          tooltip: "Open pinned messages",
        ),
        IconButton(
          onPressed: () => onOpenMemberList(context),
          tooltip: "Open member list",
          icon: Icon(Icons.people),
        ),
        RoomMenu(room),
      ].toIList(),
    );
  }
}
