import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/room_menu.dart";

class RoomAppbar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final void Function(BuildContext context)? onOpenMemberList;
  final void Function(BuildContext context) onOpenDrawer;
  final String? roomId;
  const RoomAppbar({
    required this.roomId,
    required this.isDesktop,
    required this.onOpenDrawer,
    this.onOpenMemberList,
    super.key,
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = roomId == null
        ? null
        : ref.watch(RoomsController.provider.select((value) => value[roomId!]));
    return Appbar(
      leading: isDesktop
          ? room == null
                ? null
                : ExpandableImage(
                    room.metadata?.avatar
                        ?.mxcToHttps(
                          ref.watch(
                            ClientStateController.provider.select(
                              (value) => value!.homeserverUrl!,
                            ),
                          ),
                        )
                        .toString(),
                    child: AvatarOrHash(
                      room.metadata?.avatar,
                      room.metadata?.name ?? "Unnamed Rooms",
                      height: 24,
                      fallback: Icon(Icons.numbers),
                    ),
                  )
          : DrawerButton(onPressed: () => onOpenDrawer(context)),
      scrolledUnderElevation: 0,
      title: room == null
          ? null
          : Column(
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
          onPressed: () => onOpenMemberList?.call(context),
          tooltip: "Open member list",
          icon: Icon(Icons.people),
        ),
        if (room != null) RoomMenu(room),
      ].toIList(),
    );
  }
}
