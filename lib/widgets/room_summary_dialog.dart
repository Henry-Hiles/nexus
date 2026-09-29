import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/linkified_text.dart";
import "package:nexus/models/room_summary.dart";

class const RoomSummaryDialog(
  final RoomSummary summary, {
  final IList<Widget> extraActions = const IList.empty(),
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    constraints: .loose(.fromWidth(400)),
    scrollable: true,
    contentPadding: EdgeInsets.all(24).copyWith(top: 8),
    title: Row(
      spacing: 12,
      mainAxisSize: .min,
      children: [
        if (summary.avatarUrl != null)
          ExpandableImage(
            summary.avatarUrl == null ? null : .new(mxc: summary.avatarUrl!),
            child: AvatarOrHash(
              summary.avatarUrl,
              summary.name ?? "Unnamed Room",
              height: 64,
              fallback: Icon(Icons.numbers),
            ),
          ),
        Expanded(
          child: Text(
            summary.name ?? summary.canonicalAlias ?? summary.roomId,
            overflow: .ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    ),
    content: Column(
      children: [
        ListTile(
          title: Text("${summary.joinedMembers} members"),
          leading: Icon(Icons.people),
        ),
        ListTile(
          title: SelectableText(summary.canonicalAlias ?? summary.roomId),
          leading: Icon(Icons.numbers),
        ),

        if (summary.topic != null)
          ListTile(
            isThreeLine: true,
            subtitle: LinkifiedText(
              summary.topic!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            leading: Icon(Icons.info),
          ),
      ],
    ),

    actions: [
      TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
      ...extraActions,
    ],
  );
}
