import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/room_summary_dialog.dart";

class const InvitesList({super.key})
    extends HookConsumerWidget
    implements NavPage {
  @override
  String get title => "Invites";

  @override
  IconData get icon => Icons.inbox;

  @override
  int? badgeCount(WidgetRef ref) => switch (ref.watch(
    InvitesController.provider.select((invites) => invites.length),
  )) {
    0 => null,
    final count => count,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(InvitesController.provider);
    final decliningAll = useState(false);

    Future<void> declineAll() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Decline All Invites"),
          content: Text(
            "Are you sure you want to decline all ${invites.length} invites?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Decline All"),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      decliningAll.value = true;
      await ref
          .read(InvitesController.provider.notifier)
          .declineAll()
          .onError(showError);
      if (context.mounted) decliningAll.value = false;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: invites.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: decliningAll.value ? null : declineAll,
              icon: decliningAll.value
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.clear_all),
              label: const Text("Decline all"),
            ),
      body: invites.isEmpty
          ? Center(
              child: Text(
                "No invites",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            )
          : ListView(
              // Leave room for the FAB under the last invite
              padding: const .only(left: 8, top: 8, right: 8, bottom: 88),
              children: invites.map(InviteCard.new).toList(),
            ),
    );
  }
}

class const InviteCard(final RoomSummary invite, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final name = invite.name ?? invite.canonicalAlias ?? invite.roomId;
    final inviterName =
        invite.inviterProfile?.displayName ?? invite.invitedBy?.localpart;

    return Card(
      clipBehavior: .antiAlias,
      child: ListTile(
        onTap: () => showDialog(
          context: context,
          builder: (_) => RoomSummaryDialog(invite),
        ),
        leading: AvatarOrHash(
          invite.avatarUrl,
          name,
          dimension: 40,
          fallback: invite.isDirect
              ? null
              : Icon(
                  invite.roomType == RoomType.space
                      ? Icons.workspaces
                      : Icons.numbers,
                ),
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
