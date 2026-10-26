import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/widgets/mxc_emoji.dart";
import "package:nexus/widgets/settings/image_usage_chips.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Edits an image in a pack, or only shows it if [onSave] is null.
class const PackImageSheet({
  required final String title,
  required final String shortcode,
  required final PackImage image,

  /// The other images' shortcodes, which this one can't also have.
  required final ISet<String> taken,

  /// The pack's default usage, which images have unless they set their own.
  required final ISet<ImageUsage> packUsage,
  required final void Function(String shortcode, PackImage image)? onSave,
  final VoidCallback? onRemoved,
  super.key,
}) extends HookWidget {
  static final shortcodePattern = RegExp(r"^[\w-]+$");

  @override
  Widget build(BuildContext context) {
    final shortcodeController = useTextEditingController(text: shortcode);
    final bodyController = useTextEditingController(text: image.body);
    final usage = useState(image.usage);
    final newShortcode = useValueListenable(shortcodeController).text.trim();
    final error = taken.contains(newShortcode)
        ? "Another image has this shortcode"
        : newShortcode.isNotEmpty && !shortcodePattern.hasMatch(newShortcode)
        ? "Only letters, numbers, - and _ are allowed"
        : null;
    final valid = newShortcode.isNotEmpty && error == null;

    void save() {
      final body = bodyController.text.trim();
      Navigator.of(context).pop();
      onSave!(
        newShortcode,
        image.copyWith(body: body.isEmpty ? null : body, usage: usage.value),
      );
    }

    return SheetLayout(
      title: Text(title),
      actions: [
        if (onRemoved case final onRemoved?)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemoved();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text("Remove"),
          ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(onSave == null ? "Close" : "Cancel"),
        ),
        if (onSave != null)
          TextButton(onPressed: valid ? save : null, child: Text("Save")),
      ],
      children: [
        Center(
          child: SizedBox.square(
            dimension: 128,
            child: MxcEmoji(image.url, label: shortcode),
          ),
        ),
        TextField(
          controller: shortcodeController,
          enabled: onSave != null,
          onSubmitted: valid ? (_) => save() : null,
          decoration: .new(
            labelText: "Shortcode",
            prefixText: ":",
            suffixText: ":",
            errorText: error,
          ),
        ),
        TextField(
          controller: bodyController,
          enabled: onSave != null,
          onSubmitted: valid ? (_) => save() : null,
          decoration: .new(
            labelText: "Description",
            hintText: "Read by screen readers",
          ),
        ),
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            SwitchListTile(
              title: Text("Custom usage"),
              subtitle: Text(
                usage.value.isEmpty
                    ? "Same as the pack's default (${packUsage.map(ImageUsageChips.nameOf).join(", ")})"
                    : "Used as chosen below, instead of the pack's default",
              ),
              value: usage.value.isNotEmpty,
              onChanged: onSave == null
                  ? null
                  : (custom) =>
                        usage.value = custom ? packUsage : const .empty(),
            ),
            AnimatedSize(
              duration: Durations.medium2,
              curve: Curves.easeInOut,
              alignment: .topCenter,
              child: usage.value.isEmpty
                  ? const SizedBox(width: .infinity)
                  : Padding(
                      padding: .only(top: 8),
                      child: ImageUsageChips(
                        value: usage.value,
                        onChanged: onSave == null
                            ? null
                            : (value) => usage.value = value,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
