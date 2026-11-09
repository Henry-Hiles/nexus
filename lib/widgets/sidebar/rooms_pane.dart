import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/helpers/extensions/room_destinations.dart";
import "package:nexus/widgets/common/appbar.dart";
import "package:nexus/widgets/rooms/room_title.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/common/divider_widget.dart";
import "package:nexus/widgets/common/m3e_rail_theme.dart";
import "package:nexus/widgets/rooms/room_summary_sheet.dart";
import "package:nexus/widgets/rooms/room_menu_button.dart";
import "package:nexus/widgets/rooms/space_hierarchy_sheet.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/selected_room.dart";
import "package:nexus/controllers/selected_space.dart";

class const RoomsPane({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoomId = ref.watch(SelectedRoomController.provider);
    final selectedSpace = ref.watch(SelectedSpaceController.provider)!;
    final isDm = selectedSpace.id == "dms";
    final spaceMetadata = selectedSpace.room?.metadata;
    // In the order the rail shows them, with the space's own timeline first
    final destinationIds = IList<String?>([?spaceMetadata?.id])
        .addAll(selectedSpace.allChildRooms.map((room) => room.metadata?.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: Appbar(
        // Home and DMs aren't real spaces, so they don't have a summary.
        onTap: spaceMetadata == null
            ? null
            : () => context.showAdaptiveSheet(
                (_) => RoomSummarySheet(.fromMetadata(spaceMetadata)),
              ),
        windowControls: false,
        leading: AvatarOrHash(
          spaceMetadata?.avatar,
          fallback: selectedSpace.icon == null
              ? null
              : Icon(selectedSpace.icon),
          selectedSpace.title,
        ),
        title: RoomTitle(selectedSpace.title, topic: spaceMetadata?.topic),
        backgroundColor: Colors.transparent,
        actions: .new([
          RoomMenuButton(
            selectedSpace.room,
            children: selectedSpace.allChildRooms,
          ),
        ]),
      ),
      body: M3ERailTheme(
        extensions: [
          NavigationRailM3ETheme(
            itemExpandedHeight: 48,
            iconLabelGap: 16,
            sectionHeaderSpacingTop: 0,
          ),
        ],
        builder: (context) => Padding(
          padding: const .only(top: 4),
          child: NavigationRailM3E(
            fab: selectedSpace.room == null
                ? null
                : .new(
                    icon: const Icon(Icons.explore),
                    label: "Browse space",
                    tooltip: "Browse and join rooms in this space",
                    onPressed: () => context.showAdaptiveSheet(
                      (_) => SpaceHierarchySheet(selectedSpace.id),
                    ),
                  ),
            expandedWidth: double.infinity,
            scrollable: true,
            background: Colors.transparent,
            type: .alwaysExpand,
            selectedIndex: max(0, destinationIds.indexOf(selectedRoomId)),
            sections: [
              if (selectedSpace.room case final room?
                  when spaceMetadata != null)
                .new(
                  destinations: [
                    room.toDestination(
                      isDm: isDm,
                      label: "Space timeline",
                      icon: const Icon(Icons.forum),
                    ),
                  ],
                ),
              .new(
                header: selectedSpace.room == null
                    ? null
                    : const DividerWidget(Text("Rooms")),
                destinations: selectedSpace.children.toDestinations(isDm: isDm),
              ),
              ...selectedSpace.subSpaces.map(
                (subSpace) => NavigationRailM3ESection(
                  header: DividerWidget(
                    Row(
                      mainAxisSize: .min,
                      spacing: 8,
                      children: [
                        if (subSpace.room.metadata?.avatar != null)
                          AvatarOrHash(
                            subSpace.room.metadata?.avatar,
                            subSpace.room.metadata?.name ?? "Unnamed Room",
                            dimension: 16,
                          ),
                        Flexible(
                          child: Text(
                            subSpace.room.metadata?.name ?? "Unnamed Space",
                            maxLines: 1,
                            overflow: .ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: subSpace.children.toDestinations(isDm: isDm),
                ),
              ),
            ],
            onDestinationSelected: (value) {
              ref
                  .read(KeyController.provider(KeyController.roomKey).notifier)
                  .set(destinationIds[value]);
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }
}
