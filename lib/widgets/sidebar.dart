import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/join_dialog.dart";
import "package:nexus/widgets/room_menu.dart";

class Sidebar extends HookConsumerWidget {
  final bool isDesktop;
  const Sidebar({required this.isDesktop, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpaceProvider = KeyController.provider(
      KeyController.spaceKey,
    );
    final selectedSpaceId = ref.watch(selectedSpaceProvider);
    final selectedSpaceIdNotifier = ref.watch(selectedSpaceProvider.notifier);

    final selectedRoomController = KeyController.provider(
      KeyController.roomKey,
    );
    final selectedRoomId = ref.watch(selectedRoomController);
    final selectedRoomIdNotifier = ref.watch(selectedRoomController.notifier);

    final spaces = ref.watch(SpacesController.provider);
    final indexOfSelected = spaces.indexWhere(
      (space) => space.id == selectedSpaceId,
    );
    final selectedIndex = indexOfSelected == -1 ? 0 : indexOfSelected;

    final selectedSpace =
        spaces.firstWhereOrNull((space) => space.id == selectedSpaceId) ??
        spaces.first;

    final indexOfSelectedRoom = selectedSpace.children.indexWhere(
      (room) => room.metadata?.id == selectedRoomId,
    );
    final selectedRoomIndex = indexOfSelectedRoom == -1
        ? null
        : indexOfSelectedRoom;

    List<NavigationRailM3EDestination> roomsToDestinations(IList<Room> rooms) =>
        rooms
            .map(
              (room) => NavigationRailM3EDestination(
                label: room.metadata?.name ?? "Unnamed Room",
                badgeCount: switch (room.metadata?.unreadNotifications) {
                  0 || null => room.metadata?.unreadMessages == 0 ? null : 0,
                  int unread => unread,
                },
                icon: AvatarOrHash(
                  room.metadata?.avatar,
                  room.metadata?.name ?? "Unnamed Room",
                  fallback: selectedSpaceId == "dms"
                      ? null
                      : Icon(Icons.numbers),
                  //  space.client.headers,
                ),
              ),
            )
            .toList();

    return Drawer(
      width: 340,
      shape: Border(),
      child: Row(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              extensions: [
                NavigationRailM3ETheme(
                  itemCollapsedHeight: 48,
                  itemVerticalGap: 0,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: NavigationRailM3E(
                type: .alwaysCollapse,
                labelBehavior: .alwaysHide,
                scrollable: true,
                onDestinationSelected: (value) {
                  selectedSpaceIdNotifier.set(spaces[value].id);
                  selectedRoomIdNotifier.set(
                    spaces[value].children.firstOrNull?.metadata?.id,
                  );
                },
                sections: [
                  .new(
                    destinations: spaces
                        .map(
                          (space) => NavigationRailM3EDestination(
                            badgeCount: switch (space.children.fold(
                              0,
                              (previousValue, room) =>
                                  previousValue +
                                  (room.metadata?.unreadNotifications ?? 0),
                            )) {
                              0 =>
                                space.children.any(
                                      (room) =>
                                          room.metadata?.unreadMessages != 0,
                                    )
                                    ? 0
                                    : null,
                              int badgeCount => badgeCount,
                            },
                            short: true,
                            icon: AvatarOrHash(
                              space.room?.metadata?.avatar,
                              fallback: space.icon == null
                                  ? null
                                  : Icon(space.icon),
                              space.title,
                            ),
                            label: space.title,
                          ),
                        )
                        .toList(),
                  ),
                ],
                selectedIndex: selectedIndex,
                trailingAtBottom: true,
                trailing: Padding(
                  padding: .symmetric(vertical: 16),
                  child: Column(
                    spacing: 8,
                    children: [
                      PopupMenuButton(
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => JoinDialog(ref),
                            ),
                            child: ListTile(
                              title: Text("Join an existing room (or space)"),
                              leading: Icon(Icons.numbers),
                            ),
                          ),
                          PopupMenuItem(
                            onTap: null,
                            child: ListTile(
                              title: Text("Create a new room"),
                              leading: Icon(Icons.add),
                            ),
                          ),
                        ],
                        icon: Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: "Explore other rooms",
                        onPressed: null,
                        icon: Icon(Icons.explore),
                      ),
                      IconButton(
                        tooltip: "Open settings",
                        onPressed: null,
                        //  () => Navigator.of(
                        //   context,
                        // ).push(MaterialPageRoute(builder: (_) => SettingsPage())),
                        icon: Icon(Icons.settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Scaffold(
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
                  RoomMenu(
                    selectedSpace.room,
                    children: selectedSpace.children,
                  ),
                ],
              ),
              body: Theme(
                data: Theme.of(context).copyWith(
                  extensions: [
                    NavigationRailM3ETheme(
                      itemExpandedHeight: 48,
                      iconLabelGap: 16,
                    ),
                  ],
                ),
                child: NavigationRailM3E(
                  expandedWidth: 360,
                  scrollable: true,
                  background: Colors.transparent,
                  type: .alwaysExpand,
                  selectedIndex: selectedRoomIndex ?? 0,
                  sections: [
                    .new(
                      destinations: roomsToDestinations(selectedSpace.children),
                    ),
                    for (final subSpace in selectedSpace.subSpaces)
                      .new(
                        header: Text(
                          subSpace.room.metadata?.name ?? "Unnamed Room",
                        ),
                        destinations: roomsToDestinations(subSpace.children),
                      ),
                  ],
                  onDestinationSelected: (value) {
                    selectedRoomIdNotifier.set(
                      selectedSpace.children[value].metadata?.id,
                    );
                    if (!isDesktop) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
