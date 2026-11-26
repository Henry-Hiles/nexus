import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

// Later names first, then those from MSC4191, which servers may still use
enum AccountManagementAction(final List<String> names) {
  devicesList(["org.matrix.devices_list", "org.matrix.sessions_list"]),
  accountDeactivate(["org.matrix.account_deactivate"]),
  crossSigningReset(["org.matrix.cross_signing_reset"]),
}

class const AccountManagement(final Uri uri, final ISet<String> actions) {
  Uri? urlFor(AccountManagementAction action) =>
      switch (action.names.firstWhereOrNull(actions.contains)) {
        final name? => uri.replace(
          queryParameters: {...uri.queryParameters, "action": name},
        ),
        null => null,
      };
}
