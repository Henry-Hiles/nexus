import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/key_controller.dart";
import "package:nexus/controllers/selected_space_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
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
    final selectedSpace = ref.watch(selectedSpaceProvider);
    final selectedSpaceNotifier = ref.watch(selectedSpaceProvider.notifier);

    final selectedRoomController = KeyController.provider(
      KeyController.roomKey,
    );
    final selectedRoom = ref.watch(selectedRoomController);
    final selectedRoomNotifier = ref.watch(selectedRoomController.notifier);

    return Drawer(
      shape: Border(),
      child: Row(
        children: [
          ref
              .watch(SpacesController.provider)
              .when(
                loading: SizedBox.shrink,
                error: (error, stack) {
                  debugPrintStack(label: error.toString(), stackTrace: stack);
                  throw error;
                },
                data: (spaces) {
                  final indexOfSelected = spaces.indexWhere(
                    (space) => space.id == selectedSpace,
                  );
                  final selectedIndex = indexOfSelected == -1
                      ? 0
                      : indexOfSelected;

                  return NavigationRail(
                    scrollable: true,
                    onDestinationSelected: (value) {
                      selectedSpaceNotifier.set(spaces[value].id);
                      selectedRoomNotifier.set(
                        spaces[value].children.firstOrNull?.roomData.id,
                      );
                    },
                    destinations: spaces
                        .map(
                          (space) => NavigationRailDestination(
                            icon: AvatarOrHash(
                              space.avatar,
                              fallback: space.icon == null
                                  ? null
                                  : Icon(space.icon),
                              space.title,
                              headers: space.client.headers,
                              hasBadge:
                                  space.children.firstWhereOrNull(
                                    (room) => room.roomData.hasNewMessages,
                                  ) !=
                                  null,
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
                                      final roomAlias =
                                          useTextEditingController();
                                      return AlertDialog(
                                        title: Text("Join a Room"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            onPressed: Navigator.of(
                                              context,
                                            ).pop,
                                            child: Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final parsed = roomAlias.text
                                                  .parseIdentifierIntoParts();
                                              final alias =
                                                  parsed?.primaryIdentifier ??
                                                  roomAlias.text;

                                              Navigator.of(alertContext).pop();

                                              final scaffoldMessenger =
                                                  ScaffoldMessenger.of(context);

                                              final snackbar = scaffoldMessenger
                                                  .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Joining room...",
                                                      ),
                                                      duration: Duration(
                                                        days: 999,
                                                      ),
                                                    ),
                                                  );

                                              final client = await ref.watch(
                                                ClientController
                                                    .provider
                                                    .future,
                                              );

                                              try {
                                                final id = await client
                                                    .joinRoom(
                                                      alias,
                                                      via: parsed?.via.toList(),
                                                    );

                                                snackbar.close();

                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Room successfully joined.",
                                                    ),
                                                    action: SnackBarAction(
                                                      label: "Open",
                                                      onPressed: () async {
                                                        final spaces = await ref
                                                            .watch(
                                                              SpacesController
                                                                  .provider
                                                                  .future,
                                                            );

                                                        final space = spaces
                                                            .firstWhereOrNull(
                                                              (space) =>
                                                                  space.id ==
                                                                  id,
                                                            );

                                                        await selectedSpaceNotifier.set(
                                                          space?.id ??
                                                              spaces
                                                                  .firstWhere(
                                                                    (space) =>
                                                                        space.children.firstWhereOrNull(
                                                                          (
                                                                            child,
                                                                          ) =>
                                                                              child.roomData.id ==
                                                                              id,
                                                                        ) !=
                                                                        null,
                                                                  )
                                                                  .id,
                                                        );

                                                        if (space == null) {
                                                          await selectedRoomNotifier
                                                              .set(id);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                );
                                              } catch (error) {
                                                snackbar.close();
                                                if (context.mounted) {
                                                  scaffoldMessenger.showSnackBar(
                                                    SnackBar(
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .errorContainer,
                                                      content: Text(
                                                        error.toString(),
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onErrorContainer,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
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
                                  title: Text(
                                    "Join an existing room (or space)",
                                  ),
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
                            onPressed: () => Navigator.of(context).push(
                              // TODO: explore public rooms/spaces
                              MaterialPageRoute(builder: (_) => SettingsPage()),
                            ),
                            icon: Icon(Icons.explore),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SettingsPage()),
                            ),
                            icon: Icon(Icons.settings),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          Expanded(
            child: ref
                .watch(SelectedSpaceController.provider)
                .betterWhen(
                  data: (space) {
                    final indexOfSelected = space.children.indexWhere(
                      (room) => room.roomData.id == selectedRoom,
                    );
                    final selectedIndex = indexOfSelected == -1
                        ? space.children.isEmpty
                              ? null
                              : 0
                        : indexOfSelected;

                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        leading: AvatarOrHash(
                          space.avatar,
                          fallback: space.icon == null
                              ? null
                              : Icon(space.icon),
                          space.title,
                          headers: space.client.headers,
                        ),
                        title: Text(
                          space.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.transparent,
                        actions: [
                          if (space.roomData != null) RoomMenu(space.roomData!),
                        ],
                      ),
                      body: NavigationRail(
                        scrollable: true,
                        backgroundColor: Colors.transparent,
                        extended: true,
                        selectedIndex: selectedIndex,
                        destinations: space.children
                            .map(
                              (room) => NavigationRailDestination(
                                label: Text(room.title),
                                icon: AvatarOrHash(
                                  hasBadge: room.roomData.hasNewMessages,
                                  room.avatar,
                                  room.title,
                                  fallback: selectedSpace == "dms"
                                      ? null
                                      : Icon(Icons.numbers),
                                  headers: space.client.headers,
                                ),
                              ),
                            )
                            .toList(),
                        onDestinationSelected: (value) => selectedRoomNotifier
                            .set(space.children[value].roomData.id),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
