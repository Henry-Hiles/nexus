import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/settings/power_level_field.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Gives something, like an event type, its own power level.
class const PowerLevelEntrySheet({
  required final String title,

  /// The label of the field for what's given the power level.
  required final String keyLabel,
  required final String keyHint,

  /// The user's own power level, which they can't set levels above.
  required final double ownLevel,
  required final void Function(String key, int level) onSave,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final keyController = useTextEditingController();
    final levelController = useTextEditingController(text: "0");
    final key = useValueListenable(keyController).text.trim();
    final level = PowerLevelField.levelFrom(
      useValueListenable(levelController).text,
      ownLevel,
    );
    final valid = key.isNotEmpty && level != null;

    void save() {
      Navigator.of(context).pop();
      onSave(key, level!);
    }

    return SheetLayout(
      title: Text(title),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: valid ? save : null, child: Text("Save")),
      ],
      children: [
        TextField(
          controller: keyController,
          autofocus: true,
          decoration: .new(labelText: keyLabel, hintText: keyHint),
        ),
        PowerLevelField(
          controller: levelController,
          ownLevel: ownLevel,
          onSubmitted: valid ? save : null,
        ),
      ],
    );
  }
}
