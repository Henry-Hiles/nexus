import "dart:math";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:m3e_design/m3e_design.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/helpers/extensions/room_destinations.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/adaptive_menu_button.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/room_title.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/create_room_sheet.dart";
import "package:nexus/widgets/start_dm_sheet.dart";
import "package:nexus/widgets/divider_widget.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/pages/settings.dart";
import "package:nexus/widgets/join_sheet.dart";
import "package:nexus/widgets/room_summary_sheet.dart";
import "package:nexus/widgets/room_menu_button.dart";
import "package:nexus/widgets/space_hierarchy_sheet.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/spaces.dart";
import "package:collection/collection.dart";

// Needed for navigation_rail_m3e (#65).
import "package:flutter/material.dart" as old_mat;

class const RoomList({super.key}) extends ConsumerWidget implements NavPage {
  @override
  String get title => "Rooms";

  @override
  IconData get icon => Icons.list;

  @override
  int? badgeCount(WidgetRef ref) {
    final (notifications, hasUnread) = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms.values.fold(
          (0, false),
          (total, room) => (
            total.$1 + (room.metadata?.unreadNotifications ?? 0),
            total.$2 || (room.metadata?.unreadMessages ?? 0) > 0,
          ),
        ),
      ),
    );

    return notifications > 0
        ? notifications
        : hasUnread
        ? 0
        : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(SpacesController.provider);
    if (spacesAsync.value == null) {
      return switch (spacesAsync) {
        AsyncError(:final error, :final stackTrace) => ErrorDialog(
          error,
          stackTrace,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      };
    }

    return const Row(
      children: [
        SpacesRail(),
        Expanded(child: RoomsPane()),
      ],
    );
  }
}

class const SpacesRail({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(
      SpacesController.provider.select((async) => async.requireValue),
    );
    final selectedSpaceId = ref.watch(
      KeyController.provider(KeyController.spaceKey)
          .select((async) => async.requireValue),
    );

    return MaterialUiCompatibilityBridge(
      child: Builder(
        builder: (context) => old_mat.Theme(
          data: old_mat.Theme.of(context).copyWith(
            extensions: [
              NavigationRailM3ETheme(
                itemCollapsedHeight: 48,
                itemVerticalGap: 0,
              ),
            ],
          ),
          child: Container(
            color: NavigationRailTokensAdapter(context).containerColor,
            padding: .only(top: 16),
            child: NavigationRailM3E(
              type: .alwaysCollapse,
              labelBehavior: .alwaysHide,
              scrollable: true,
              onDestinationSelected: (value) {
                ref
                    .read(
                      KeyController.provider(KeyController.spaceKey).notifier,
                    )
                    .set(spaces[value].id);
                ref
                    .read(
                      KeyController.provider(KeyController.roomKey).notifier,
                    )
                    .set(spaces[value].children.firstOrNull?.metadata?.id);
              },
              sections: [
                .new(
                  destinations: spaces.map((space) {
                    final notifications = space.allChildRooms.fold(
                      0,
                      (sum, room) =>
                          sum + (room.metadata?.unreadNotifications ?? 0),
                    );

                    return NavigationRailM3EDestination(
                      badgeCount: notifications > 0
                          ? notifications
                          : space.allChildRooms.any(
                              (room) => room.metadata?.unreadMessages != 0,
                            )
                          ? 0
                          : null,
                      short: true,
                      icon: AvatarOrHash(
                        dimension: 28,
                        space.room?.metadata?.avatar,
                        fallback: space.icon == null ? null : Icon(space.icon),
                        space.title,
                      ),
                      label: space.title,
                    );
                  }).toList(),
                ),
              ],
              selectedIndex: max(
                0,
                spaces.indexWhere((space) => space.id == selectedSpaceId),
              ),
              trailingAtBottom: true,
              trailing: Padding(
                padding: .only(top: 8),
                child: Column(
                  children: [
                    AdaptiveMenuButton(
                      tooltip: "Add a room",
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () =>
                              context.showAdaptiveSheet((_) => JoinSheet(ref)),
                          child: const ListTile(
                            title: Text("Join an existing room (or space)"),
                            leading: Icon(Icons.numbers),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => context.showAdaptiveSheet(
                            (_) => const CreateRoomSheet(),
                          ),
                          child: const ListTile(
                            title: Text("Create a new room (or space)"),
                            leading: Icon(Icons.add),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => context.showAdaptiveSheet(
                            (_) => const StartDmSheet(),
                          ),
                          child: const ListTile(
                            title: Text("Start a direct message"),
                            leading: Icon(Icons.person_add),
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.add),
                    ),
                    const IconButton(
                      tooltip: "Explore other rooms",
                      onPressed: null,
                      icon: Icon(Icons.explore),
                    ),
                    IconButton(
                      tooltip: "Open settings",
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => SettingsPage(),
                      ),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const RoomsPane({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpaceId = ref.watch(
      KeyController.provider(KeyController.spaceKey)
          .select((async) => async.requireValue),
    );
    final selectedRoomId = ref.watch(
      KeyController.provider(KeyController.roomKey)
          .select((async) => async.requireValue),
    );
    final selectedSpace = ref.watch(
      SpacesController.provider.select((async) {
        final spaces = async.requireValue;
        return spaces.firstWhereOrNull(
              (space) => space.id == selectedSpaceId,
            ) ??
            spaces.first;
      }),
    );
    final isDm = selectedSpace.id == "dms";
    final spaceMetadata = selectedSpace.room?.metadata;

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
      body: MaterialUiCompatibilityBridge(
        child: Builder(
          builder: (context) {
            final theme = old_mat.Theme.of(context);
            return old_mat.Theme(
              data: theme.copyWith(
                extensions: [
                  NavigationRailM3ETheme(
                    itemExpandedHeight: 48,
                    iconLabelGap: 16,
                    sectionHeaderSpacingTop: 0,
                  ),
                  // Otherwise the FAB label falls back to Roboto
                  M3ETheme.defaults(theme.colorScheme).copyWith(
                    typography: .defaultFor(
                      theme.brightness,
                      baseOverride: theme.textTheme,
                    ),
                  ),
                ],
              ),
              child: Padding(
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
                  selectedIndex: max(
                    0,
                    selectedSpace.allChildRooms.indexWhere(
                      (room) => room.metadata?.id == selectedRoomId,
                    ),
                  ),
                  sections: [
                    .new(
                      header: selectedSpace.room == null
                          ? null
                          : const DividerWidget(Text("Rooms")),
                      destinations: selectedSpace.children.toDestinations(
                        isDm: isDm,
                      ),
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
                                  subSpace.room.metadata?.name ??
                                      "Unnamed Room",
                                  dimension: 16,
                                ),
                              Flexible(
                                child: Text(
                                  subSpace.room.metadata?.name ??
                                      "Unnamed Space",
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        destinations: subSpace.children.toDestinations(
                          isDm: isDm,
                        ),
                      ),
                    ),
                  ],
                  onDestinationSelected: (value) {
                    ref
                        .read(
                          KeyController.provider(KeyController.roomKey)
                              .notifier,
                        )
                        .set(selectedSpace.allChildRooms[value].metadata?.id);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
