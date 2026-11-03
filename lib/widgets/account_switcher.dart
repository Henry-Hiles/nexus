import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/accounts.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/helpers/extensions/log_out.dart";
import "package:nexus/main.dart";
import "package:nexus/models/account.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

/// Switches between, adds and logs out of accounts. With [onlyWithOthers], it's
/// hidden when there's only one account.
class const AccountSwitcher({final bool onlyWithOthers = false, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danger = Theme.of(context).colorScheme.error;
    final accounts = ref.watch(AccountsController.provider).value;
    final activeId = ref.watch(ActiveAccountController.provider);
    if (accounts == null || (onlyWithOthers && accounts.length < 2)) {
      return const SizedBox.shrink();
    }

    String nameOf(Account account) =>
        account.displayName ?? account.userId ?? "New account";

    Widget avatarOf(Account account, double dimension) => AvatarOrHash(
      account.avatar,
      nameOf(account),
      dimension: dimension,
      fallback: account.userId == null
          ? Icon(Icons.account_circle, size: dimension)
          : null,
    );

    final active = accounts.firstWhereOrNull(
      (account) => account.id == activeId,
    );

    void switchTo(String accountId) => ref
        .read(ActiveAccountController.provider.notifier)
        .switchTo(accountId)
        .onError(showError);

    final loggingOut = ref.watch(LogOut.mutation).isPending;

    return AdaptiveMenuButton<void>(
      tooltip: loggingOut ? "Logging out..." : "Switch account",
      enabled: !loggingOut,
      icon: loggingOut
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(),
            )
          : active == null
          ? const Icon(Icons.account_circle)
          : avatarOf(active, 28),
      itemBuilder: (_) => [
        for (final account in accounts)
          PopupMenuItem(
            onTap: () => switchTo(account.id),
            child: ListTile(
              selected: account.id == activeId,
              leading: avatarOf(account, 32),
              title: Text(nameOf(account)),
              subtitle: switch (account) {
                Account(displayName: _?, :final userId?) => Text(userId),
                _ => null,
              },
              trailing: account.userId == null
                  ? null
                  // Inside the menu, so it can close it
                  : Builder(
                      builder: (menuContext) => IconButton(
                        tooltip: "Log out",
                        icon: Icon(Icons.logout, color: danger),
                        onPressed: () async {
                          Navigator.of(menuContext).pop();

                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text("Log out of ${nameOf(account)}?"),
                              content: Text(
                                account.id == activeId
                                    ? "You'll be switched to another account, or returned to the login page if this is your only one."
                                    : "You'll stop receiving notifications for this account.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: danger,
                                  ),
                                  child: const Text("Log out"),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;

                          await ref.logOut(account.id).onError(showError);
                        },
                      ),
                    ),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            ref
                .read(AccountsController.provider.notifier)
                .save(.new(id: id))
                .then((_) => switchTo(id))
                .onError(showError);
          },
          child: const ListTile(
            leading: Icon(Icons.person_add),
            title: Text("Add account"),
          ),
        ),
      ],
    );
  }
}
