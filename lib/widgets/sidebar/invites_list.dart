import "package:nexus/widgets/sidebar/invite_card.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/main.dart";
import "package:nexus/models/nav_page.dart";

class const InvitesList({super.key}) extends ConsumerWidget implements NavPage {
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
    final decliningAll = ref
        .watch(InvitesController.declineAllMutation)
        .isPending;

    Future<void> declineAll() async {
      final confirmed = await context.showAdaptiveSheet<bool>(
        (context) => SheetLayout(
          title: const Text("Decline All Invites"),
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
          children: [
            Text(
              "Are you sure you want to decline all ${invites.length} invites?",
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await InvitesController.declineAllMutation
          .run(
            ref,
            (_) => ref.read(InvitesController.provider.notifier).declineAll(),
          )
          .onError(showError);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: invites.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: decliningAll ? null : declineAll,
              icon: decliningAll
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
