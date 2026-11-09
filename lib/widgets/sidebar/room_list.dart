import "package:nexus/widgets/sidebar/spaces_rail.dart";
import "package:nexus/widgets/sidebar/rooms_pane.dart";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/common/error_dialog.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/spaces.dart";

class const RoomList({super.key}) extends ConsumerWidget implements NavPage {
  @override
  String get title => "Rooms";

  @override
  IconData get icon => Icons.list;

  @override
  int? badgeCount(WidgetRef ref) {
    final (notifications, hasUnread) = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms.values.fold(
          (0, false),
          (total, room) => (
            total.$1 + (room.metadata?.unreadNotifications ?? 0),
            total.$2 || (room.metadata?.unreadMessages ?? 0) > 0,
          ),
        ),
      ),
    );

    return notifications > 0
        ? notifications
        : hasUnread
        ? 0
        : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(SpacesController.provider);
    if (spacesAsync.value == null) {
      return switch (spacesAsync) {
        AsyncError(:final error, :final stackTrace) => ErrorDialog(
          error,
          stackTrace,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      };
    }

    return const Row(
      children: [
        SpacesRail(),
        Expanded(child: RoomsPane()),
      ],
    );
  }
}
