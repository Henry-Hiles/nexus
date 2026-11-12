import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/notification_request.dart";

/// Runs [child] as one account, in a [ProviderScope] of its own that's
/// replaced when switching accounts, so no state leaks between them.
class const AccountScope({
  required final String initialAccountId,
  required final Widget child,
  final List<ProviderObserver>? observers,
  final Duration? Function(int retryCount, Object error)? retry,

  /// Applied to each account's scope, after its own, e.g. for test fakes
  final List<Override> overrides = const [],
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final active = useState<AccountSwitch>((
      accountId: initialAccountId,
      notificationRowId: null,
    ));

    return ProviderScope(
      key: ValueKey(active.value.accountId),
      retry: retry,
      observers: observers,
      overrides: [
        ActiveAccountController.provider.overrideWith(
          () => ActiveAccountController(
            active.value.accountId,
            (next) => active.value = next,
          ),
        ),
        NotificationRequestController.provider.overrideWithBuild(
          (_, _) => active.value.notificationRowId,
        ),
        ...overrides,
      ],
      child: child,
    );
  }
}
