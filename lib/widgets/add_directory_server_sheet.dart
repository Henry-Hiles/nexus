import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";

class const AddDirectoryServerSheet({
  required final ISet<String> existing,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final text = useValueListenable(controller).text;
    final server = text.trim().toLowerCase();
    final error = server.isEmpty
        ? null
        : !server.isValidServerName
        ? "Enter a server name, without https:// or a path"
        : existing.contains(server)
        ? "This server has already been added"
        : null;
    final valid = server.isNotEmpty && error == null;

    void submit() {
      if (valid) Navigator.of(context).pop(server);
    }

    return SheetLayout(
      title: const Text("Add Server"),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text("Cancel"),
        ),
        TextButton(onPressed: valid ? submit : null, child: const Text("Add")),
      ],
      children: [
        const Text("Enter a server to browse the public rooms of."),
        TextField(
          controller: controller,
          autofocus: true,
          keyboardType: .url,
          onSubmitted: (_) => submit(),
          decoration: .new(
            labelText: "Server name",
            hintText: "matrix.org",
            errorText: error,
          ),
        ),
      ],
    );
  }
}
