import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/widgets/renderers/related_event_line.dart";

/// A line for each message a pinned events event pinned, in green, and each one
/// it unpinned, in red and struck through.
class const PinnedEventsDiff(
  final String roomId, {
  required final IList<String> pinned,
  required final IList<String> unpinned,

  /// If set, tapping a message jumps to it.
  final JumpToEvent? jumpToEvent,
  super.key,
}) extends StatelessWidget {
  static const maxShown = 5;

  @override
  Widget build(BuildContext context) {
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

          return RelatedEventLine(
            roomId,
            change.$1,
            color: color,
            decoration: decoration,
            jumpToEvent: jumpToEvent,
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
