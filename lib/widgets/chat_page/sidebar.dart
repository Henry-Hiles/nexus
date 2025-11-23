import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/current_room_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/controllers/selected_space_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/pages/settings_page.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/unread.dart";

class Sidebar extends HookConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpaceProvider = SelectedSpaceController.provider;
    final selectedSpace = ref.watch(selectedSpaceProvider);
    final selectedSpaceNotifier = ref.watch(selectedSpaceProvider.notifier);

    final selectedRoomController = SelectedRoomController.provider;
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
                data: (spaces) => NavigationRail(
                  scrollable: true,
                  onDestinationSelected: (value) {
                    selectedRoomNotifier.set(0);
                    selectedSpaceNotifier.set(value);
                    ref
                        .watch(CurrentRoomController.provider.notifier)
                        .set(spaces[value].children[0]);
                  },
                  destinations: spaces
                      .map(
                        (space) => NavigationRailDestination(
                          icon: Unread(
                            isUnread:
                                space.children.firstWhereOrNull(
                                  (room) => room.roomData.hasNewMessages,
                                ) !=
                                null,
                            child: AvatarOrHash(
                              space.avatar,
                              fallback: space.icon,
                              space.title,
                              headers: space.client.headers,
                            ),
                          ),
                          label: Text(space.title),
                          padding: EdgeInsets.only(top: 4),
                        ),
                      )
                      .toList(),
                  selectedIndex: selectedSpace,
                  trailingAtBottom: true,
                  trailing: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: IconButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => SettingsPage())),
                      icon: Icon(Icons.settings),
                    ),
                  ),
                ),
              ),
          Expanded(
            child: ref
                .watch(SpacesController.provider)
                .betterWhen(
                  data: (spaces) {
                    final space = spaces[selectedSpace];
                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        leading: AvatarOrHash(
                          space.avatar,
                          fallback: space.icon,
                          space.title,
                          headers: space.client.headers,
                        ),
                        title: Text(
                          space.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      body: NavigationRail(
                        scrollable: true,
                        backgroundColor: Colors.transparent,
                        extended: true,
                        selectedIndex: space.children.isEmpty
                            ? null
                            : selectedRoom,
                        destinations: space.children
                            .map(
                              (room) => NavigationRailDestination(
                                label: Text(room.title),
                                icon: Unread(
                                  isUnread: room.roomData.hasNewMessages,
                                  child: AvatarOrHash(
                                    room.avatar,
                                    room.title,
                                    fallback: selectedSpace == 1
                                        ? null
                                        : Icon(Icons.numbers),
                                    headers: space.client.headers,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onDestinationSelected: (value) {
                          selectedRoomNotifier.set(value);
                          ref
                              .watch(CurrentRoomController.provider.notifier)
                              .set(space.children[value]);
                        },
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
