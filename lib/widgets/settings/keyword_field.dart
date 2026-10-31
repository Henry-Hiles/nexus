import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";

/// Adds a keyword, which notifies with a highlight and sound for messages
/// containing it.
class const KeywordField({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = Saving.use();
    final controller = useTextEditingController();
    final keyword = useValueListenable(controller).text.trim();
    final exists = ref.watch(
      AccountDataController.provider.select(
        (data) => data.pushRules.global.find(.content, keyword) != null,
      ),
    );

    // Keywords are their rules' IDs, which can't be like these
    final error = keyword.startsWith(".")
        ? "Can't start with a ."
        : keyword.contains(RegExp(r"[/\\]"))
        ? r"Can't contain / or \"
        : exists
        ? "Already a keyword"
        : null;
    final canAdd = keyword.isNotEmpty && error == null && !saving.active;

    void add() {
      if (!canAdd) return;
      saving
          .run(() async {
            await ref
                .read(AccountDataController.provider.notifier)
                .savePushRule(
                  .content,
                  .new(
                    ruleId: keyword,
                    pattern: keyword,
                    actions: .highlightWithSound,
                  ),
                );
            if (context.mounted) controller.clear();
          })
          .onError(showError);
    }

    return Padding(
      padding: .symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        enabled: !saving.active,
        onSubmitted: (_) => add(),
        decoration: .new(
          labelText: "New keyword",
          helperText: "Matches whole words. * matches anything, and ? matches one character.",
          errorText: error,
          suffixIcon: IconButton(
            tooltip: "Add keyword",
            icon: Icon(Icons.add),
            onPressed: canAdd ? add : null,
          ),
        ),
      ),
    );
  }
}
