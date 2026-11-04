import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/widgets/settings/member_chooser.dart";
import "package:nexus/widgets/settings/power_level_field.dart";

/// Chooses users of [roomId] to give a power level of their own.
class const AddUsersPowerLevelSheet({
  required final String roomId,

  /// Users who already have a level, or can't be given one, so aren't suggested.
  required final ISet<String> existing,

  /// The user's own power level, which they can't set levels above.
  required final double ownLevel,
  required final void Function(ISet<String> users, int level) onSave,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final chosen = useState(const ISet<String>.empty());
    final levelController = useTextEditingController(text: "0");
    final level = PowerLevelField.levelFrom(
      useValueListenable(levelController).text,
      ownLevel,
    );

    final valid = chosen.value.isNotEmpty && level != null;
    void save() {
      Navigator.of(context).pop();
      onSave(chosen.value, level!);
    }

    return SheetLayout(
      title: Text("Add Users"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: valid ? save : null, child: Text("Save")),
      ],
      children: [
        MemberChooser(
          roomId: roomId,
          chosen: chosen.value,
          excluded: existing,
          excludedError: "Already has a power level",
          onAdded: (id) => chosen.value = chosen.value.add(id),
          onRemoved: (id) => chosen.value = chosen.value.remove(id),
          label: "Add user",
          removeTooltip: "Remove user",
          autofocus: true,
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
