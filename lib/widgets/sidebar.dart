import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/invites_list.dart";
import "package:nexus/widgets/notifications_list.dart";
import "package:nexus/widgets/room_list.dart";

class const Sidebar({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    const pages = <NavPage>[RoomList(), NotificationsList(), InvitesList()];

    return Drawer(
      width: 330,
      shape: Border(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pages[selectedIndex.value],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex.value,
          destinations: pages
              .map(
                (element) => NavigationDestination(
                  icon: Icon(element.icon),
                  label: element.title,
                ),
              )
              .toList(),
          onDestinationSelected: (value) => selectedIndex.value = value,
        ),
      ),
    );
  }
}
