import "package:collection/collection.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:nexus/controllers/accounts.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/unified_push.dart";
import "package:nexus/main.dart";

extension LogOut on MutationTarget {
  static final mutation = Mutation<void>();

  Future<void> logOut(String accountId) => mutation.run(this, (_) async {
    final accounts = await container.read(AccountsController.provider.future);
    final account = accounts.firstWhereOrNull(
      (account) => account.id == accountId,
    );
    if (account == null) return;

    final isActive =
        accountId == container.read(ActiveAccountController.provider);
    final client = isActive
        ? container.read(ClientController.provider.notifier)
        : container.read(ClientController.forAccount(accountId).notifier);

    if (account.deviceId case final deviceId?) {
      await container
          .read(UnifiedPushController.provider.notifier)
          .deregister(deviceId)
          .onError(showError);
    }
    if (isActive) container.invalidate(InitCompleteController.provider);
    await client.logout().onError(showError);

    if (!isActive) {
      container.invalidate(ClientController.forAccount(accountId));
      await container
          .read(AccountsController.provider.notifier)
          .remove(accountId);
      return;
    }

    final other = accounts.firstWhereOrNull(
      (account) => account.id != accountId,
    );
    if (other == null) return;

    await container
        .read(AccountsController.provider.notifier)
        .remove(accountId);
    await container
        .read(ActiveAccountController.provider.notifier)
        .switchTo(other.id);
  });
}
