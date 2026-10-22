import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/local_aliases.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";
import "package:nexus/models/gomuks_exception.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const LocalAliasesSheet(
  final String roomId, {

  /// Called after an alias is deleted, e.g. to stop publishing it.
  final Future<void> Function(String alias)? onRemoved,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = LocalAliasesController.provider(roomId);
    final saving = Saving.use();
    final controller = useTextEditingController();
    final localpart = useValueListenable(controller).text.trim();
    final server = ref.watch(
      ClientStateController.provider.select(
        (state) => state?.userId?.split(":").skip(1).join(":"),
      ),
    );

    final error = useState<String?>(null);

    void add() {
      if (localpart.isEmpty || server == null) return;
      saving
          .run(() async {
            try {
              await ref.read(provider.notifier).add("#$localpart:$server");
              controller.clear();
            } on GomuksException catch (exception) {
              // Taken, by this room or another, which is shown on the field
              if (exception.statusCode != 409) rethrow;
              if (context.mounted) error.value = "This alias already exists";
            }
          })
          .onError(showError);
    }

    return SheetLayout(
      title: Text("Local Aliases"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Close")),
      ],
      children: [
        Text(
          "Addresses for the room on your server. Publish them to show them to others.",
        ),
        ref
            .watch(provider)
            .betterWhen(
              data: (aliases) => aliases.isEmpty
                  ? Text("No local aliases")
                  : Column(
                      children: aliases
                          .map(
                            (alias) => ListTile(
                              title: Text(alias, overflow: .ellipsis),
                              trailing: IconButton(
                                tooltip: "Delete alias",
                                icon: Icon(Icons.delete),
                                onPressed: saving.active
                                    ? null
                                    : () => saving
                                          .run(() async {
                                            await ref
                                                .read(provider.notifier)
                                                .remove(alias);
                                            await onRemoved?.call(alias);
                                          })
                                          .onError(showError),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
        TextField(
          controller: controller,
          enabled: !saving.active,
          onChanged: (_) => error.value = null,
          onSubmitted: (_) => add(),
          decoration: .new(
            labelText: "New alias",
            errorText: error.value,
            prefixText: "#",
            suffixText: server == null ? null : ":$server",
            suffixIcon: IconButton(
              tooltip: "Add alias",
              icon: Icon(Icons.add),
              onPressed: localpart.isEmpty || saving.active ? null : add,
            ),
          ),
        ),
      ],
    );
  }
}
