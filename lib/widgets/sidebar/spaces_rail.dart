import "dart:math";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/widgets/common/account_switcher.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/rooms/create_room_sheet.dart";
import "package:nexus/widgets/users/start_dm_sheet.dart";
import "package:nexus/widgets/pages/explore.dart";
import "package:nexus/widgets/pages/settings.dart";
import "package:nexus/widgets/rooms/join_sheet.dart";
import "package:nexus/widgets/common/m3e_rail_theme.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/spaces.dart";

class const SpacesRail({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(
      SpacesController.provider.select((async) => async.requireValue),
    );
    final selectedSpaceId = ref.watch(
      KeyController.provider(KeyController.spaceKey)
          .select((async) => async.requireValue),
    );

    return M3ERailTheme(
      extensions: [
        NavigationRailM3ETheme(itemCollapsedHeight: 48, itemVerticalGap: 0),
      ],
      builder: (context) => Container(
        color: NavigationRailTokensAdapter(context).containerColor,
        padding: .only(top: 16),
        child: NavigationRailM3E(
          type: .alwaysCollapse,
          labelBehavior: .alwaysHide,
          scrollable: true,
          onDestinationSelected: (value) {
            ref
                .read(KeyController.provider(KeyController.spaceKey).notifier)
                .set(spaces[value].id);
            ref
                .read(KeyController.provider(KeyController.roomKey).notifier)
                .set(spaces[value].children.firstOrNull?.metadata?.id);
          },
          sections: [
            .new(
              destinations: spaces.map((space) {
                final notifications = space.allChildRooms.fold(
                  0,
                  (sum, room) =>
                      sum + (room.metadata?.unreadNotifications ?? 0),
                );

                return NavigationRailM3EDestination(
                  badgeCount: notifications > 0
                      ? notifications
                      : space.allChildRooms.any(
                          (room) => room.metadata?.unreadMessages != 0,
                        )
                      ? 0
                      : null,
                  short: true,
                  icon: AvatarOrHash(
                    dimension: 28,
                    space.room?.metadata?.avatar,
                    fallback: space.icon == null ? null : Icon(space.icon),
                    space.title,
                  ),
                  label: space.title,
                );
              }).toList(),
            ),
          ],
          selectedIndex: max(
            0,
            spaces.indexWhere((space) => space.id == selectedSpaceId),
          ),
          trailingAtBottom: true,
          trailing: Padding(
            padding: .only(top: 8),
            child: Column(
              children: [
                AdaptiveMenuButton(
                  tooltip: "Add a room",
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () =>
                          context.showAdaptiveSheet((_) => JoinSheet(ref)),
                      child: const ListTile(
                        title: Text("Join an existing room (or space)"),
                        leading: Icon(Icons.numbers),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => context.showAdaptiveSheet(
                        (_) => const CreateRoomSheet(),
                      ),
                      child: const ListTile(
                        title: Text("Create a new room (or space)"),
                        leading: Icon(Icons.add),
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => context.showAdaptiveSheet(
                        (_) => const StartDmSheet(),
                      ),
                      child: const ListTile(
                        title: Text("Start a direct message"),
                        leading: Icon(Icons.person_add),
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.add),
                ),
                const AccountSwitcher(),
                IconButton(
                  tooltip: "Explore other rooms",
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExplorePage()),
                  ),
                  icon: const Icon(Icons.explore),
                ),
                IconButton(
                  tooltip: "Open settings",
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => SettingsPage(),
                  ),
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
