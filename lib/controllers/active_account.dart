import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/accounts.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:nexus/models/account.dart";
import "package:shared_preferences/shared_preferences.dart";

typedef AccountSwitch = ({String accountId, int? notificationRowId});

class ActiveAccountController(
  final String accountId,
  final void Function(AccountSwitch next) restart,
) extends Notifier<String> {
  @override
  String build() => accountId;

  static Future<String> stored() async =>
      await SharedPreferencesAsync().getString(
        KeyController.activeAccountKey,
      ) ??
      Account.legacyId;

  /// Restarts the app as [accountId], then opens [notificationRowId] if given.
  Future<void> switchTo(String accountId, {int? notificationRowId}) async {
    if (accountId == state) {
      if (notificationRowId != null) {
        ref
            .read(NotificationRequestController.provider.notifier)
            .request(notificationRowId);
      }
      return;
    }

    final accounts = await ref.read(AccountsController.provider.future);
    if (!accounts.any((account) => account.id == accountId)) return;

    if (accounts.firstWhereOrNull((account) => account.id == state)
        case Account(userId: null)) {
      await ref.read(AccountsController.provider.notifier).remove(state);
    }

    await ref
        .read(KeyController.provider(KeyController.activeAccountKey).notifier)
        .set(accountId);

    restart((accountId: accountId, notificationRowId: notificationRowId));
  }

  static final provider = NotifierProvider<ActiveAccountController, String>(
    () => throw UnimplementedError("Provided by AccountScope"),
  );
}
