import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

/// A line for each message a pinned events event pinned, in green, and each one
/// it unpinned, in red and struck through.
class const PinnedEventsDiff(
  final String roomId, {
  required final IList<String> pinned,
  required final IList<String> unpinned,

  /// If set, tapping a message jumps to it.
  final JumpToEvent? jumpToEvent,
  super.key,
}) extends ConsumerWidget {
  static const maxShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    final changes = [
      ...pinned.map((eventId) => (eventId, unpinned: false)),
      ...unpinned.map((eventId) => (eventId, unpinned: true)),
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        ...changes.take(maxShown).map((change) {
          final color = change.unpinned
              ? theme.colorScheme.error
              : theme.successScheme.primary;
          final decoration = change.unpinned
              ? TextDecoration.lineThrough
              : null;

          return DefaultTextStyle.merge(
            style: style?.copyWith(
              color: color,
              decoration: decoration,
              decorationColor: color,
            ),
            child: switch (ref.watch(
              EventController.provider(
                .new(roomId: roomId, eventId: change.$1),
              ),
            )) {
              // Keeps showing the event while it reloads
              AsyncValue(value: final event?) => InkWell(
                borderRadius: .circular(4),
                hoverColor: color.withValues(alpha: 0.12),
                onTap: jumpToEvent == null
                    ? null
                    : () => jumpToEvent!(event.rowId),
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    // Other events already say who sent them
                    if (event.content is MessageContent) ...[
                      MessageDisplayname(
                        event,
                        clickable: false,
                        shouldWrap: false,
                        style: .new(
                          color: color,
                          fontWeight: .bold,
                          decoration: decoration,
                          decorationColor: color,
                        ),
                      ),
                      Text(": "),
                    ],
                    Flexible(
                      child: IgnorePointer(
                        child: EventRenderer(
                          event.rowId,
                          roomId: event.roomId,
                          textOnly: true,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AsyncLoading() => SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
              // Like if it was deleted, or the server won't share it
              _ => Text("Message not found"),
            },
          );
        }),
        if (changes.length > maxShown)
          Text(
            "+${changes.length - maxShown} more",
            style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
