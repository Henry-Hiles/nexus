import "dart:math";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/divider_widget.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/pages/settings.dart";
import "package:nexus/widgets/join_dialog.dart";
import "package:nexus/widgets/room_menu_button.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/models/room.dart";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

// Needed for navigation_rail_m3e (#65).
import "package:flutter/material.dart" as old_mat;

List<NavigationRailM3EDestination> roomDestinations(
  IList<Room> rooms, {
  required bool isDm,
}) => [
  for (final room in rooms)
    .new(
      label: room.metadata?.name ?? "Unnamed Room",
      badgeCount: switch (room.metadata?.unreadNotifications) {
        0 || null => room.metadata?.unreadMessages == 0 ? null : 0,
        int unread => unread,
      },
      icon: AvatarOrHash(
        room.metadata?.avatar,
        room.metadata?.name ?? "Unnamed Room",
        fallback: isDm ? null : const Icon(Icons.numbers),
      ),
    ),
];

class const RoomList({super.key}) extends ConsumerWidget implements NavPage {
  @override
  String get title => "Rooms";

  @override
  IconData get icon => Icons.list;

  // TODO: Show unread badge here and on sidebar hamburger
  @override
  Future<int>? badgeBuilder(WidgetRef ref) => null;

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
                    PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => JoinDialog(ref),
                          ),
                          child: const ListTile(
                            title: Text("Join an existing room (or space)"),
                            leading: Icon(Icons.numbers),
                          ),
                        ),
                        const PopupMenuItem(
                          onTap: null,
                          child: ListTile(
                            title: Text("Create a new room"),
                            leading: Icon(Icons.add),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: AvatarOrHash(
          selectedSpace.room?.metadata?.avatar,
          fallback: selectedSpace.icon == null
              ? null
              : Icon(selectedSpace.icon),
          selectedSpace.title,
        ),
        title: Text(selectedSpace.title, overflow: .ellipsis),
        backgroundColor: Colors.transparent,
        actions: [
          RoomMenuButton(
            selectedSpace.room,
            children: selectedSpace.allChildRooms,
          ),
        ],
      ),
      body: MaterialUiCompatibilityBridge(
        child: Builder(
          builder: (context) => old_mat.Theme(
            data: old_mat.Theme.of(context).copyWith(
              extensions: [
                NavigationRailM3ETheme(
                  itemExpandedHeight: 48,
                  iconLabelGap: 16,
                ),
              ],
            ),
            child: NavigationRailM3E(
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
                  destinations: roomDestinations(
                    selectedSpace.children,
                    isDm: isDm,
                  ),
                ),
                for (final subSpace in selectedSpace.subSpaces)
                  .new(
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
                    destinations: roomDestinations(
                      subSpace.children,
                      isDm: isDm,
                    ),
                  ),
              ],
              onDestinationSelected: (value) {
                ref
                    .read(
                      KeyController.provider(KeyController.roomKey).notifier,
                    )
                    .set(selectedSpace.allChildRooms[value].metadata?.id);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
