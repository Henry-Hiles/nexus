import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/models/account_management.dart";

/// Where the homeserver lets the user manage their account, if it says.
class AccountManagementController extends AsyncNotifier<AccountManagement?> {
  @override
  Future<AccountManagement?> build() async {
    final homeserver = ref.watch(
      ClientStateController.provider.select((state) => state?.homeserverUrl),
    );
    if (homeserver == null) return null;

    return ref
        .read(ClientController.provider.notifier)
        .getAccountManagement(.parse(homeserver));
  }

  static final provider =
      AsyncNotifierProvider<AccountManagementController, AccountManagement?>(
        AccountManagementController.new,
      );
}
