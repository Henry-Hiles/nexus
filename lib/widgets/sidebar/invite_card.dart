import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/room_summary_display.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/rooms/room_summary_sheet.dart";

class const InviteCard(final RoomSummary invite, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responding = ref
        .watch(InvitesController.respondMutation(invite.roomId))
        .isPending;
    final name = invite.name ?? invite.canonicalAlias ?? invite.roomId;
    final inviterName =
        invite.inviterProfile?.displayName ?? invite.invitedBy?.localpart;

    return Card(
      clipBehavior: .antiAlias,
      child: ListTile(
        onTap: responding
            ? null
            : () => context.showAdaptiveSheet((_) => RoomSummarySheet(invite)),
        trailing: responding
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(),
              )
            : null,
        leading: AvatarOrHash(
          invite.avatarUrl,
          name,
          dimension: 40,
          fallback: invite.isDirect ? null : Icon(invite.icon),
        ),
        title: Text(name, maxLines: 1, overflow: .ellipsis),
        subtitle: Text(
          [
            if (inviterName != null)
              "${invite.isDirect ? "Direct message from" : "Invited by"} $inviterName",
          ].join("\n"),
          maxLines: 2,
          overflow: .ellipsis,
        ),
      ),
    );
  }
}
