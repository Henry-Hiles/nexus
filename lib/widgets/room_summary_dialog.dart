import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/linkified_text.dart";
import "package:nexus/models/room_summary.dart";

class const RoomSummaryDialog(
  final RoomSummary summary, {
  final IList<String>? via,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
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
              "",
              dimension: 64,
              fallback: Icon(Icons.numbers),
            ),
          ),
        Expanded(
          child: Text(
            summary.name ?? summary.canonicalAlias ?? "Unnamed Room",
            overflow: .ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    ),
    content: Column(
      children: [
        ListTile(
          title: Text(
            "${summary.joinedMembers ?? "Unknown number of"} members",
          ),
          leading: Icon(Icons.people),
        ),
        ListTile(
          title: SelectableText(summary.canonicalAlias ?? summary.roomId),
          leading: Icon(Icons.numbers),
        ),

        if (summary.topic != null)
          ListTile(
            titleAlignment: ListTileTitleAlignment.titleHeight,
            title: LinkifiedText(
              summary.topic!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            leading: Icon(Icons.info),
          ),
      ],
    ),

    actions: [
      TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
      if (via != null)
        TextButton(
          onPressed: () async {
            // Capture everything before the dialog closes.
            final container = ProviderScope.containerOf(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final colors = Theme.of(context).colorScheme;
            Navigator.of(context).pop();

            final roomIdOrAlias = summary.canonicalAlias ?? summary.roomId;

            final snackbar = scaffoldMessenger.showSnackBar(
              .new(
                content: Text("Joining room $roomIdOrAlias."),
                duration: Duration(days: 999),
              ),
            );

            try {
              final id = await container
                  .read(ClientController.provider.notifier)
                  .joinRoom(.new(roomIdOrAlias: summary.roomId, via: via!));

              snackbar.close();

              scaffoldMessenger.showSnackBar(
                .new(
                  content: Text("Room $roomIdOrAlias successfully joined."),
                  action: .new(
                    label: "Open",
                    onPressed: () => container.focusRoom(id),
                  ),
                ),
              );
            } catch (error) {
              snackbar.close();
              scaffoldMessenger.showSnackBar(
                .new(
                  backgroundColor: colors.errorContainer,
                  content: Text(
                    error.toString(),
                    style: .new(color: colors.onErrorContainer),
                  ),
                ),
              );
            }
          },
          child: Text("Join"),
        ),
    ],
  );
}
