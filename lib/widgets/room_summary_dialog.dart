import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/join_room.dart";
import "package:nexus/main.dart";
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
  Widget build(BuildContext context) {
    final name = summary.name ?? summary.canonicalAlias ?? summary.roomId;
    final isInvite = summary.membership == .invite;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
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
          if (summary.invitedBy case final invitedBy?)
            ListTile(
              leading: AvatarOrHash(
                summary.inviterProfile?.avatarUrl,
                summary.inviterProfile?.displayName ?? invitedBy.localpart,
              ),
              title: Text(
                "${summary.isDirect ? "Direct message from" : "Invited by"} ${summary.inviterProfile?.displayName ?? invitedBy.localpart}",
              ),
              subtitle: SelectableText(invitedBy),
            ),
          // Invite state never includes the member count
          if (summary.joinedMembers != null || !isInvite)
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
          if (summary.encryption != null)
            ListTile(title: Text("Encrypted"), leading: Icon(Icons.lock)),
          if (summary.worldReadable == true)
            ListTile(
              title: Text("Anyone can read the history"),
              leading: Icon(Icons.public),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        if (isInvite) ...[
          TextButton(
            onPressed: () {
              final container = ProviderScope.containerOf(context);
              Navigator.of(context).pop();

              container
                  .read(InvitesController.provider.notifier)
                  .decline(summary.roomId)
                  .onError(showError);
            },
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text("Decline"),
          ),
          TextButton(
            onPressed: () {
              final container = ProviderScope.containerOf(context);

              context
                  .joinRoom(
                    .new(roomIdOrAlias: summary.roomId, fromInvite: true),
                    name: name,
                  )
                  .then((roomId) {
                    if (roomId != null) {
                      container
                          .read(InvitesController.provider.notifier)
                          .remove(summary.roomId);
                    }
                  });
              Navigator.of(context).pop();
            },
            child: Text("Accept"),
          ),
        ] else if (via != null)
          TextButton(
            onPressed: () {
              context.joinRoom(
                .new(roomIdOrAlias: summary.roomId, via: via!),
                name: name,
              );
              Navigator.of(context).pop();
            },
            child: Text("Join"),
          ),
      ],
    );
  }
}
