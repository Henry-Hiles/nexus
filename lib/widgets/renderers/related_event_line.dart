import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/helpers/extensions/is_shown_as_message.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/event.dart";

/// A single line previewing another event, like the message a reaction is on,
/// with its sender if it's a message.
class const RelatedEventLine(
  final String roomId,
  final String eventId, {
  final Color? color,
  final TextDecoration? decoration,

  /// If set, tapping the event jumps to it.
  final JumpToEvent? jumpToEvent,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = this.color ?? theme.colorScheme.onSurfaceVariant;

    return DefaultTextStyle.merge(
      style: theme.textTheme.labelMedium?.copyWith(
        color: color,
        decoration: decoration,
        decorationColor: color,
      ),
      child: switch (ref.watch(
        EventController.provider(.new(roomId: roomId, eventId: eventId)),
      )) {
        AsyncValue(value: final rowId?) => InkWell(
          borderRadius: .circular(4),
          hoverColor: color.withValues(alpha: 0.12),
          onTap: jumpToEvent == null ? null : () => jumpToEvent!(rowId),
          child: Row(
            mainAxisSize: .min,
            children: [
              if (ref.watch(
                    RoomsController.provider.select(
                      (rooms) => rooms[roomId]?.events[rowId],
                    ),
                  )
                  case final event?
                  when event.hasMessageContent &&
                      event.relationType != "m.replace") ...[
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
                    rowId,
                    roomId: roomId,
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
        _ => Text("Message not found"),
      },
    );
  }
}
