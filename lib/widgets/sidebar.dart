import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/current_room_controller.dart";
import "package:nexus/controllers/spaces_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/widgets/avatar.dart";

class Sidebar extends HookConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpace = useState(0);
    final selectedRoom = useState(0);
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
                  onDestinationSelected: (value) => selectedSpace.value = value,
                  destinations: spaces
                      .map(
                        (space) => NavigationRailDestination(
                          icon: Avatar(space.avatar, space.title),
                          label: Text(space.title),
                          padding: EdgeInsets.only(top: 4),
                        ),
                      )
                      .toList(),
                  selectedIndex: selectedSpace.value,
                ),
              ),
          Expanded(
            child: ref
                .watch(SpacesController.provider)
                .betterWhen(
                  data: (spaces) {
                    final space = spaces[selectedSpace.value];
                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        title: Row(
                          children: [
                            Avatar(space.avatar, space.title),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                space.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      body: NavigationRail(
                        scrollable: true,
                        backgroundColor: Colors.transparent,
                        extended: true,
                        destinations: space.children
                            .map(
                              (room) => NavigationRailDestination(
                                icon: Avatar(
                                  room.avatar,
                                  room.title,
                                  fallback: selectedSpace.value == 1
                                      ? null
                                      : Icon(Icons.numbers),
                                ),
                                label: Text(room.title),
                              ),
                            )
                            .toList(),
                        onDestinationSelected: (value) {
                          selectedRoom.value = value;
                          ref
                              .watch(CurrentRoomController.provider.notifier)
                              .set(space.children[value]);
                        },
                        selectedIndex: space.children.isEmpty
                            ? null
                            : selectedRoom.value,
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
