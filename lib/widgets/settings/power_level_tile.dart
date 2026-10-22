import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/settings/power_level_field.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Sets the power level needed for something.
class const PowerLevelTile({
  required final Widget leading,
  required final String title,
  required final String? description,
  required final int value,

  /// The user's own power level, which they can't set or change levels above.
  required final double ownLevel,

  /// Disables the tile if null.
  required final void Function(int value)? onChanged,

  /// Shows a button to remove the level if given, disabled along with the tile.
  final VoidCallback? onRemoved,

  /// If given, asked before removing the level.
  final String? removeConfirmation,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null && value <= ownLevel;

    Future<void> remove() async {
      if (removeConfirmation case final confirmation?) {
        final confirmed = await context.showAdaptiveSheet<bool>(
          (context) => SheetLayout(
            title: Text("Remove Power Level"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text("Remove"),
              ),
            ],
            children: [Text(confirmation)],
          ),
        );
        if (confirmed != true) return;
      }
      onRemoved!();
    }

    return ListTile(
      enabled: enabled,
      leading: leading,
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      trailing: Row(
        mainAxisSize: .min,
        spacing: 8,
        children: [
          Chip(
            label: Text(
              "$value",
              style: enabled ? null : .new(color: Colors.grey),
            ),
          ),
          if (onRemoved != null)
            IconButton(
              tooltip: "Remove",
              icon: Icon(Icons.delete),
              onPressed: enabled ? remove : null,
            ),
        ],
      ),
      onTap: () => context.showAdaptiveSheet(
        (context) => HookBuilder(
          builder: (context) {
            final controller = useTextEditingController(text: "$value");
            final level = PowerLevelField.levelFrom(
              useValueListenable(controller).text,
              ownLevel,
            );

            void save() {
              Navigator.of(context).pop();
              if (level != value) onChanged!(level!);
            }

            return SheetLayout(
              title: Text(title),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: level == null ? null : save,
                  child: Text("Save"),
                ),
              ],
              children: [
                PowerLevelField(
                  controller: controller,
                  ownLevel: ownLevel,
                  autofocus: true,
                  onSubmitted: level == null ? null : save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
