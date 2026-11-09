import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/join_room.dart";
import "package:nexus/helpers/extensions/room_summary_display.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/rooms/knock_sheet.dart";
import "package:nexus/widgets/rooms/room_summary_sheet.dart";

class const RoomDirectoryCard(
  final RoomSummary summary, {
  required final IList<String> via,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joined = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms.containsKey(summary.roomId),
      ),
    );
    final mustKnock = ref.watch(
      RoomsController.provider.select(
        (rooms) => summary.mustKnock(
          summary.allowedRoomIds.where(rooms.containsKey).toISet(),
        ),
      ),
    );
    final theme = Theme.of(context);
    final name = summary.displayName;

    return Card.filled(
      clipBehavior: .antiAlias,
      margin: .zero,
      child: InkWell(
        onTap: () => context.showAdaptiveSheet(
          (_) => RoomSummarySheet(summary, via: joined ? null : via),
        ),
        child: Padding(
          padding: const .all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: 12,
            children: [
              Row(
                spacing: 12,
                children: [
                  AvatarOrHash(
                    summary.avatarUrl,
                    name,
                    dimension: 48,
                    fallback: Icon(summary.icon),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (summary.details case final details
                            when details.isNotEmpty)
                          Text(
                            details,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  summary.topic ?? summary.canonicalAlias ?? "",
                  maxLines: 3,
                  overflow: .ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Align(
                alignment: .centerRight,
                child: joined
                    ? FilledButton.tonal(
                        onPressed: () async {
                          final container = ProviderScope.containerOf(context);
                          Navigator.of(context).pop();
                          await container.focusRoom(summary.roomId);
                          container
                              .read(SidebarPageController.provider.notifier)
                              .set(.rooms);
                        },
                        child: const Text("Open"),
                      )
                    : mustKnock
                    ? FilledButton(
                        onPressed: () => context.showAdaptiveSheet(
                          (_) =>
                              KnockSheet(summary.roomId, name: name, via: via),
                        ),
                        child: const Text("Knock"),
                      )
                    : FilledButton(
                        onPressed: () => context.joinRoom(
                          .new(roomIdOrAlias: summary.roomId, via: via),
                          name: name,
                        ),
                        child: const Text("Join"),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
