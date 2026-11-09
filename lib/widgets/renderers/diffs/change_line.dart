import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";

/// A line of what a state event changed, like a room's old name, struck
/// through, then its new one.
class const ChangeLine({
  /// What changed, e.g. `Denied`, in bold before the items.
  final String? label,
  final IList<String> removed = const .empty(),
  final IList<String> added = const .empty(),
  required final Color removedColor,
  required final Color addedColor,

  /// Whether to quote the items, like server names, but not whole sentences.
  final bool quoted = true,

  /// Shown after the items, like a change that isn't one of them.
  final List<Widget> trailing = const [],

  /// How many removed and how many added items to show, as some events, like
  /// a room's first server ACL, can change hundreds.
  final int maxShown = 5,

  /// The most lines each item can take, as some, like topics, can be long.
  final int maxLines = 2,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;

    Iterable<Widget> items(
      IList<String> items, {
      required Color color,
      required bool struck,
    }) => [
      ...items
          .take(maxShown)
          .map(
            (item) => Text(
              quoted ? "\"$item\"" : item,
              maxLines: maxLines,
              overflow: .ellipsis,
              style: style?.copyWith(
                color: color,
                decoration: struck ? .lineThrough : null,
                decorationColor: color,
              ),
            ),
          ),
      if (items.length > maxShown)
        Text(
          "+${items.length - maxShown} more",
          style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: .center,
      children: [
        if (label case final label?)
          Text(label, style: style?.copyWith(fontWeight: .bold)),
        ...items(removed, color: removedColor, struck: true),
        ...items(added, color: addedColor, struck: false),
        ...trailing,
      ],
    );
  }
}
