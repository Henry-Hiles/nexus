import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Chooses which of a room's [aliases] it publishes, and which one of those is canonical.
class const AliasesSheet({
  required final ISet<String> aliases,
  required final String? canonical,
  required final ISet<String> alternatives,

  /// The canonical alias, and the other published ones.
  required final void Function(String? canonical, ISet<String> alternatives)
  onSave,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final chosenCanonical = useState(canonical);
    final published = useState(alternatives.addAll([?canonical]));

    void setPublished(String alias, bool isPublished) {
      published.value = isPublished
          ? published.value.add(alias)
          : published.value.remove(alias);
      if (!isPublished && chosenCanonical.value == alias) {
        chosenCanonical.value = null;
      }
    }

    return SheetLayout(
      title: Text("Aliases"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave(
              chosenCanonical.value,
              published.value.removeAll([?chosenCanonical.value]),
            );
          },
          child: Text("Save"),
        ),
      ],
      children: [
        Text(
          "Star an item to set it as the room's canonical alias, the alias used to advertise and access the room",
        ),
        Text(
          "Other checked items will be set as alternate aliases, which can still be used to join/access the room but are not as prominently advertised.",
        ),
        if (aliases.isEmpty)
          Text("No aliases, add a local alias first")
        else
          ...aliases.map(
            (alias) => CheckboxListTile(
              value: published.value.contains(alias),
              onChanged: (checked) => setPublished(alias, checked ?? false),
              title: Text(alias, overflow: .ellipsis),
              secondary: IconButton(
                tooltip: chosenCanonical.value == alias
                    ? "Canonical alias"
                    : "Make canonical alias",
                isSelected: chosenCanonical.value == alias,
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                onPressed: () {
                  chosenCanonical.value = alias;
                  setPublished(alias, true);
                },
              ),
            ),
          ),
      ],
    );
  }
}
