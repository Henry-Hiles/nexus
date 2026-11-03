import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/open_link_info.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/tombstone.dart";
import "package:nexus/models/event.dart";

class const TombstoneBanner(final Event tombstone, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final content = tombstone.content;
    final sender = tombstone.sender;

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: .symmetric(horizontal: 16, vertical: 8),
      margin: .only(top: 4),
      child: Row(
        spacing: 12,
        children: [
          Icon(Icons.upgrade),
          Expanded(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  "This room has been replaced and is no longer active.",
                  style: .new(fontWeight: .bold),
                ),
                if (content case TombstoneContent(:final body)
                    when body.isNotEmpty)
                  Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (content case TombstoneContent(:final replacementRoom))
            FilledButton.icon(
              onPressed: () => ref
                  .openLinkInfo(context, (
                    identifier: replacementRoom,
                    eventId: null,
                    via: [sender.substring(sender.indexOf(":") + 1)].lock,
                  ))
                  .onError(showError),
              label: Text("New room"),
              icon: Icon(Icons.open_in_new),
            ),
        ],
      ),
    );
  }
}
