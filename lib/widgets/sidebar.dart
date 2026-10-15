import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/models/sidebar_page.dart";
import "package:nexus/widgets/invites_list.dart";
import "package:nexus/widgets/notifications_list.dart";
import "package:nexus/widgets/room_list.dart";

class const Sidebar({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(SidebarPageController.provider);
    final pages = SidebarPage.values.map<NavPage>(
      (page) => switch (page) {
        .rooms => const RoomList(),
        .notifications => const NotificationsList(),
        .invites => const InvitesList(),
      },
    );

    return Drawer(
      width: 330,
      shape: Border(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pages.elementAt(selected.index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.index,
          destinations: pages.map((page) {
            final badgeCount = page.badgeCount(ref);

            return NavigationDestination(
              icon: Badge.count(
                count: badgeCount ?? 0,
                isLabelVisible: badgeCount != null,
                child: Icon(page.icon),
              ),
              label: page.title,
            );
          }).toList(),
          onDestinationSelected: (index) => ref
              .read(SidebarPageController.provider.notifier)
              .set(SidebarPage.values[index]),
        ),
      ),
    );
  }
}
