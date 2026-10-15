import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/models/sidebar_page.dart";
import "package:nexus/widgets/count_badge.dart";
import "package:nexus/widgets/invites_list.dart";
import "package:nexus/widgets/notifications_list.dart";
import "package:nexus/widgets/room_list.dart";

class const Sidebar({super.key}) extends ConsumerWidget {
  static NavPage pageFor(SidebarPage page) => switch (page) {
    .rooms => const RoomList(),
    .notifications => const NotificationsList(),
    .invites => const InvitesList(),
  };

  /// The badges of every tab added together, e.g. for the drawer button.
  ///
  /// Like [NavPage.badgeCount], null means no badges and 0 means only dots.
  static int? totalBadgeCount(WidgetRef ref) {
    final counts = SidebarPage.values
        .map((page) => pageFor(page).badgeCount(ref))
        .nonNulls;

    return counts.isEmpty ? null : counts.sum;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(SidebarPageController.provider);
    final pages = SidebarPage.values.map(pageFor);

    return Drawer(
      width: 330,
      shape: Border(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: pages.elementAt(selected.index),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.index,
          destinations: pages
              .map(
                (page) => NavigationDestination(
                  icon: CountBadge(
                    page.badgeCount(ref),
                    child: Icon(page.icon),
                  ),
                  label: page.title,
                ),
              )
              .toList(),
          onDestinationSelected: (index) => ref
              .read(SidebarPageController.provider.notifier)
              .set(SidebarPage.values[index]),
        ),
      ),
    );
  }
}
