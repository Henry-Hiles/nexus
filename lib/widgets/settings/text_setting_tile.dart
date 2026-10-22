import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const TextSettingTile({
  required final Icon icon,
  required final String title,
  required final String description,
  required final String? value,

  /// Disables the tile if null, and while a returned future runs.
  required final FutureOr<void> Function(String value)? onChanged,
  final bool multiline = false,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final saving = Saving.use();
    Future<void> change(String value) => saving.run(() => onChanged!(value));

    return ListTile(
      enabled: onChanged != null && !saving.active,
      leading: icon,
      title: Text(title),
      subtitle: Text(
        value?.isNotEmpty == true ? value! : description,
        maxLines: 2,
        overflow: .ellipsis,
      ),
      onTap: () => context.showAdaptiveSheet(
        (context) => HookBuilder(
          builder: (context) {
            final controller = useTextEditingController(text: value);

            void save() {
              Navigator.of(context).pop();
              change(controller.text.trim());
            }

            return SheetLayout(
              title: Text(title),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text("Cancel"),
                ),
                TextButton(onPressed: save, child: Text("Save")),
              ],
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: .sentences,
                  minLines: 1,
                  maxLines: multiline ? 6 : 1,
                  onSubmitted: multiline ? null : (_) => save(),
                  decoration: .new(labelText: title),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
