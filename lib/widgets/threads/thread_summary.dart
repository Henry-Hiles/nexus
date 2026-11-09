import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/thread_events.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

/// How many replies are in the thread from [root], and the latest one, or nothing if it has none.
class const ThreadSummary(
  final Event root, {
  required final VoidCallback onTap,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final thread = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms[root.roomId]?.thread(root),
      ),
    );

    if (thread case (:final count, :final latest) when count > 0) {
      return Card(
        margin: .only(top: 8),
        color: colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: .symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: .min,
                  spacing: 6,
                  children: [
                    Icon(Icons.forum, size: 16, color: colorScheme.primary),
                    Text(
                      "$count ${count == 1 ? "reply" : "replies"}",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                if (latest != null)
                  IgnorePointer(
                    child: Row(
                      mainAxisSize: .min,
                      spacing: 8,
                      children: [
                        MessageAvatar(latest, height: 24),
                        Flexible(
                          child: MessageDisplayname(latest, shouldWrap: false),
                        ),
                        Flexible(
                          flex: 2,
                          child: EventRenderer(
                            latest.rowId,
                            roomId: latest.roomId,
                            textOnly: true,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }
}
