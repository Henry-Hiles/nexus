import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/room_menu_button.dart";
import "package:nexus/widgets/room_summary_dialog.dart";

final class const RoomAppbar({
  required final String? roomId,
  required final bool isDesktop,
  required final void Function() onOpenDrawer,
  final void Function(BuildContext context)? onOpenMemberList,
  final void Function()? onOpenPinnedMessagesList,
  super.key,
}) extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = roomId == null
        ? null
        : ref.watch(RoomsController.provider.select((value) => value[roomId!]));

    return Appbar(
      onTap: room?.metadata == null
          ? null
          : () => showDialog(
              context: context,
              builder: (context) => RoomSummaryDialog(
                .new(
                  roomId: room!.metadata!.id,
                  joinedMembers:
                      room.metadata!.lazyLoadSummary?.joinedMemberCount,
                  avatarUrl: room.metadata?.avatar,
                  canonicalAlias: room.metadata?.canonicalAlias,
                  name: room.metadata?.name,
                  topic: room.metadata?.topic,
                ),
              ),
            ),
      leading: isDesktop
          ? room == null
                ? null
                : AvatarOrHash(
                    room.metadata?.avatar,
                    room.metadata?.name ?? "Unnamed Room",
                    dimension: 24,
                    fallback: Icon(Icons.numbers),
                  )
          : DrawerButton(onPressed: onOpenDrawer),
      scrolledUnderElevation: 0,
      title: room == null
          ? null
          : Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  room.metadata?.name ?? "Unnamed Room",
                  overflow: .ellipsis,
                  maxLines: 1,
                ),
                if (room.metadata?.topic?.isNotEmpty == true)
                  Text(
                    room.metadata!.topic!,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
      actions: .new(
        room == null
            ? []
            : [
                IconButton(
                  onPressed: onOpenPinnedMessagesList?.call,
                  icon: Icon(Icons.push_pin),
                  tooltip: "Open pinned messages",
                ),
                IconButton(
                  onPressed: () => onOpenMemberList?.call(context),
                  tooltip: "Open member list",
                  icon: Icon(Icons.people),
                ),
                RoomMenuButton(room),
              ],
      ),
    );
  }
}
