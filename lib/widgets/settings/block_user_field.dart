import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";

/// Blocks a user by their ID, hiding their messages and invites.
class const BlockUserField({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = Saving.use();
    final controller = useTextEditingController();
    final userId = useValueListenable(controller).text.trim();
    final blocked = ref.watch(
      AccountDataController.provider.select(
        (data) => data.ignoredUserList.contains(userId),
      ),
    );
    final ownId = ref.watch(
      ClientStateController.provider.select((state) => state?.userId),
    );

    final error = userId.isEmpty || userId.isValidUserId
        ? userId == ownId
              ? "You can't block yourself"
              : blocked
              ? "Already blocked"
              : null
        : "Enter a user ID, like @user:example.com";
    final canBlock = userId.isNotEmpty && error == null && !saving.active;

    void block() {
      if (!canBlock) return;
      saving
          .run(() async {
            await ref
                .read(AccountDataController.provider.notifier)
                .setIgnored(userId, ignored: true);
            if (context.mounted) controller.clear();
          })
          .onError(showError);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8).copyWith(top: 8),
      child: TextField(
        controller: controller,
        enabled: !saving.active,
        onSubmitted: (_) => block(),
        decoration: .new(
          labelText: "User ID",
          hintText: "@user:example.com",
          errorText: error,
          suffixIcon: IconButton(
            tooltip: "Block user",
            icon: Icon(Icons.block),
            onPressed: canBlock ? block : null,
          ),
        ),
      ),
    );
  }
}
