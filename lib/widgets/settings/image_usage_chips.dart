import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/image_pack.dart";

/// Chooses what images are used as, keeping at least one usage chosen.
class const ImageUsageChips({
  required final ISet<ImageUsage> value,

  /// Disables the chips if null.
  required final void Function(ISet<ImageUsage> value)? onChanged,
  super.key,
}) extends StatelessWidget {
  static String nameOf(ImageUsage usage) => switch (usage) {
    .emoticon => "Emoticons",
    .sticker => "Stickers",
  };

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: ImageUsage.values
        .map(
          (usage) => FilterChip(
            label: Text(nameOf(usage)),
            selected: value.contains(usage),
            onSelected:
                onChanged == null ||
                    (value.length == 1 && value.contains(usage))
                ? null
                : (selected) => onChanged!(
                    selected ? value.add(usage) : value.remove(usage),
                  ),
          ),
        )
        .toList(),
  );
}
