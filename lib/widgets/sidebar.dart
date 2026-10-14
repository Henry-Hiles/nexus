import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/invites_list.dart";
import "package:nexus/widgets/notifications_list.dart";
import "package:nexus/widgets/room_list.dart";

class const Sidebar({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pages = <NavPage>[RoomList(), NotificationsList(), InvitesList()];
    final notificationsIndex = pages.indexWhere(
      (page) => page is NotificationsList,
    );

    final selectedIndex = useState(
      ref.read(NotificationRequestController.provider) == null
          ? 0
          : notificationsIndex,
    );

    ref.listen(NotificationRequestController.provider, (_, next) {
      if (next != null) selectedIndex.value = notificationsIndex;
    });

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
