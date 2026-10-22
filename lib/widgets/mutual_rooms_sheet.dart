import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/mutual_rooms.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// The rooms the user shares with [userId].
class const MutualRoomsSheet(final String userId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetLayout(
    title: Text("Mutual Rooms"),
    actions: [
      TextButton(onPressed: Navigator.of(context).pop, child: Text("Close")),
    ],
    children: [
      ref
          .watch(MutualRoomsController.provider(userId))
          .betterWhen(
            data: (roomIds) {
              final rooms = ref.watch(
                RoomsController.provider.select(
                  (allRooms) => roomIds
                      .map((roomId) => allRooms[roomId]?.metadata)
                      .nonNulls
                      .toIList(),
                ),
              );

              return rooms.isEmpty
                  ? Text("No mutual rooms")
                  : Column(
                      children: rooms
                          .map(
                            (room) => ListTile(
                              leading: AvatarOrHash(
                                room.avatar,
                                room.name ?? "Unnamed Room",
                                fallback: Icon(Icons.numbers),
                              ),
                              title: Text(
                                room.name ?? "Unnamed Room",
                                overflow: .ellipsis,
                              ),
                              onTap: () async {
                                final container = ProviderScope.containerOf(
                                  context,
                                );
                                // Closes the user popover under this too
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                                await container.focusRoom(room.id);
                                container
                                    .read(
                                      SidebarPageController.provider.notifier,
                                    )
                                    .set(.rooms);
                              },
                            ),
                          )
                          .toList(),
                    );
            },
          ),
    ],
  );
}
