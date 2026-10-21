import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/count_badge.dart";
import "package:nexus/widgets/room_menu_button.dart";
import "package:nexus/widgets/room_summary_sheet.dart";
import "package:nexus/widgets/room_title.dart";
import "package:nexus/widgets/sidebar.dart";

final class const RoomAppbar({
  required final String? roomId,
  required final bool isDesktop,
  required final void Function() onOpenDrawer,
  final void Function(BuildContext context)? onOpenMemberList,
  final void Function()? onOpenPinnedMessagesList,
  final void Function()? onOpenSearch,
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
          : () => context.showAdaptiveSheet(
              (context) => RoomSummarySheet(.fromMetadata(room!.metadata!)),
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
          : IconButton(
              onPressed: onOpenDrawer,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: CountBadge(
                Sidebar.totalBadgeCount(ref),
                child: const DrawerButtonIcon(),
              ),
            ),
      scrolledUnderElevation: 0,
      title: room == null
          ? null
          : RoomTitle(
              room.metadata?.name ?? "Unnamed Room",
              topic: room.metadata?.topic,
            ),
      actions: .new(
        room == null
            ? []
            : [
                IconButton(
                  onPressed: onOpenSearch?.call,
                  icon: Icon(Icons.search),
                  tooltip: "Search this room",
                ),
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
