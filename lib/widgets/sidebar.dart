import "package:color_hash/color_hash.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/spaces_controller.dart";

class Sidebar extends HookConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = useState(0);
    return Drawer(
      shape: Border(),
      child: Row(
        children: [
          NavigationRail(
            scrollable: true,
            useIndicator: false,
            onDestinationSelected: (value) => index.value = value,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text("Home"),
                padding: EdgeInsets.only(top: 12),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text("Messages"),
                padding: EdgeInsets.only(top: 12),
              ),
              ...ref
                  .watch(SpacesController.provider)
                  .when(
                    loading: () => [],
                    error: (error, stack) {
                      debugPrintStack(
                        label: error.toString(),
                        stackTrace: stack,
                      );
                      throw error;
                    },
                    data: (spaces) => spaces.map(
                      (space) => NavigationRailDestination(
                        icon: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child:
                                space.avatar ??
                                ColoredBox(
                                  color: ColorHash(space.roomData.name).color,
                                  child: Center(
                                    child: Text(space.roomData.name[0]),
                                  ),
                                ),
                          ),
                        ),
                        label: Text(space.roomData.name),
                        padding: EdgeInsets.only(top: 12),
                      ),
                    ),
                  ),
            ],
            selectedIndex: index.value,
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text("Some Space"),
                backgroundColor: Colors.transparent,
              ),
              body: NavigationRail(
                scrollable: true,
                backgroundColor: Colors.transparent,
                extended: true,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 1"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 2"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 3"),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.numbers),
                    label: Text("Room 4"),
                  ),
                ],
                selectedIndex: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
