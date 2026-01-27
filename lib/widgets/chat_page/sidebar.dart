import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/selected_space_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extensions/join_room_with_snackbars.dart";
import "package:nexus/pages/settings_page.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/room_menu.dart";
import "package:nexus/widgets/form_text_input.dart";

class Sidebar extends HookConsumerWidget {
  const Sidebar({super.key});

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

    final selectedSpace = ref.watch(SelectedSpaceController.provider);

    final indexOfSelectedRoom = selectedSpace.children.indexWhere(
      (room) => room.metadata?.id == selectedRoomId,
    );
    final selectedRoomIndex = indexOfSelectedRoom == -1
        ? selectedSpace.children.isEmpty
              ? null
              : 0
        : indexOfSelectedRoom;

    return Drawer(
      shape: Border(),
      child: Row(
        children: [
          NavigationRail(
            scrollable: true,
            onDestinationSelected: (value) {
              selectedSpaceIdNotifier.set(spaces[value].id);
              selectedRoomIdNotifier.set(
                spaces[value].children.firstOrNull?.metadata?.id,
              );
            },
            destinations: spaces
                .map(
                  (space) => NavigationRailDestination(
                    icon: AvatarOrHash(
                      null, // TODO: Url
                      fallback: space.icon == null ? null : Icon(space.icon),
                      space.title,
                      headers: {}, // TODO
                      hasBadge:
                          space.children.firstWhereOrNull(
                            (room) => room.metadata?.unreadMessages != 0,
                          ) !=
                          null,
                      badgeNumber: space.children.fold(
                        0,
                        (previousValue, room) =>
                            previousValue +
                            (room.metadata?.unreadNotifications ?? 0),
                      ),
                    ),
                    label: Text(space.title),
                    padding: EdgeInsets.only(top: 4),
                  ),
                )
                .toList(),
            selectedIndex: selectedIndex,
            trailingAtBottom: true,
            trailing: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                spacing: 8,
                children: [
                  PopupMenuButton(
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: () => showDialog(
                          context: context,
                          builder: (alertContext) => HookBuilder(
                            builder: (_) {
                              final roomAlias = useTextEditingController();
                              return AlertDialog(
                                title: Text("Join a Room"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Enter the room alias, ID, or a Matrix.to link.",
                                    ),
                                    SizedBox(height: 12),
                                    FormTextInput(
                                      required: false,
                                      capitalize: true,
                                      controller: roomAlias,
                                      title: "#room:server",
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: Navigator.of(context).pop,
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(alertContext).pop();

                                      final client = ref.watch(
                                        ClientController.provider.notifier,
                                      );
                                      if (context.mounted) {
                                        client.joinRoomWithSnackBars(
                                          context,
                                          roomAlias.text,
                                          ref,
                                        );
                                      }
                                    },
                                    child: Text("Join"),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        child: ListTile(
                          title: Text("Join an existing room (or space)"),
                          leading: Icon(Icons.numbers),
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () {},
                        child: ListTile(
                          title: Text("Create a new room"),
                          leading: Icon(Icons.add),
                        ),
                      ),
                    ],
                    icon: Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(title: Text("To-do")),
                    ),
                    icon: Icon(Icons.explore),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => SettingsPage())),
                    icon: Icon(Icons.settings),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: AvatarOrHash(
                  null,
                  // space.avatar, TODO
                  fallback: selectedSpace.icon == null
                      ? null
                      : Icon(selectedSpace.icon),

                  selectedSpace.title, // TODO RM
                  headers: {},
                  //  space.client.headers, TODO
                ),
                title: Text(
                  selectedSpace.title,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: Colors.transparent,
                actions: [
                  if (selectedSpace.room != null)
                    RoomMenu(
                      selectedSpace.room!,
                      children: selectedSpace.children,
                    ),
                ],
              ),
              body: NavigationRail(
                scrollable: true,
                backgroundColor: Colors.transparent,
                extended: true,
                selectedIndex: selectedRoomIndex,
                destinations: selectedSpace.children
                    .map(
                      (room) => NavigationRailDestination(
                        label: Text(room.metadata?.name ?? "Unnamed Room"),
                        icon: AvatarOrHash(
                          null,
                          hasBadge: room.metadata?.unreadMessages != 0,
                          badgeNumber: room.metadata?.unreadNotifications ?? 0,
                          // room.avatar, TODO
                          room.metadata?.name ?? "Unnamed Room",
                          fallback: selectedSpaceId == "dms"
                              ? null
                              : Icon(Icons.numbers),
                          headers: {},
                          //  space.client.headers,
                        ),
                      ),
                    )
                    .toList(),
                onDestinationSelected: (value) => selectedRoomIdNotifier.set(
                  selectedSpace.children[value].metadata?.id,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
