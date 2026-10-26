import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/file_dialog_helper.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/widgets/image_pack_avatar.dart";
import "package:nexus/widgets/mxc_emoji.dart";
import "package:nexus/widgets/settings/image_usage_chips.dart";
import "package:nexus/widgets/settings/pack_image_sheet.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Edits an image pack, or only shows it if [onSave] is null.
class const ImagePackSheet({
  required final String title,
  required final ImagePackContent content,
  required final void Function(ImagePackContent content)? onSave,
  final VoidCallback? onDeleted,

  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editable = onSave != null;
    final nameController = useTextEditingController(
      text: content.pack?.displayName,
    );
    final name = useValueListenable(nameController).text.trim();
    final avatar = useState(content.pack?.avatarUrl);
    final usage = useState(content.pack?.usage ?? const ISet.empty());
    final images = useState(content.images);
    final uploading = Saving.use();
    final packUsage = usage.value.isEmpty
        ? ISet(ImageUsage.values)
        : usage.value;
    final valid = !uploading.active && name.isNotEmpty;

    Future<void> upload(
      void Function(String filename, PackImage image) onUploaded,
    ) async {
      final file = await ref
          .read(FileDialogHelper.provider)
          .pickFile(images: true);
      if (file == null || !context.mounted) return;

      await uploading.run(() async {
        final content = await ref
            .read(ClientController.provider.notifier)
            .uploadMedia(.new(path: file.path, encrypt: false));
        if (!context.mounted) return;

        if (content case ImageMessageContent(:final url, :final info)) {
          onUploaded(file.name, PackImage(url: url, info: info));
        } else {
          throw Exception("The file isn't an image");
        }
      });
    }

    void editImage(String shortcode, PackImage image, {bool isNew = false}) =>
        context.showAdaptiveSheet(
          (_) => PackImageSheet(
            title: isNew
                ? "Add Image"
                : editable
                ? "Edit Image"
                : ":$shortcode:",
            shortcode: shortcode,
            image: image,
            taken: isNew
                ? images.value.keys.toISet()
                : images.value.keys.toISet().remove(shortcode),
            packUsage: packUsage,
            onSave: editable
                ? (newShortcode, newImage) => images.value = isNew
                      ? images.value.add(newShortcode, newImage)
                      // Replaced in place, to keep the images' order
                      : .fromEntries(
                          images.value.entries.map(
                            (entry) => entry.key == shortcode
                                ? MapEntry(newShortcode, newImage)
                                : entry,
                          ),
                        )
                : null,
            onRemoved: editable && !isNew
                ? () => images.value = images.value.remove(shortcode)
                : null,
          ),
        );

    Future<void> delete() async {
      final confirmed = await context.showAdaptiveSheet<bool>(
        (context) => SheetLayout(
          title: Text("Delete Pack"),
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
              child: Text("Delete"),
            ),
          ],
          children: [
            Text(
              "Delete this pack? Its images will no longer be available here, or to anyone using it in other rooms.",
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      Navigator.of(context).pop();
      onDeleted?.call();
    }

    void save() {
      Navigator.of(context).pop();
      onSave!(
        content.copyWith(
          images: images.value,
          pack: (content.pack ?? const PackInfo()).copyWith(
            displayName: name,
            avatarUrl: avatar.value,
            usage: usage.value,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return SheetLayout(
      title: Text(title),
      actions: [
        if (onDeleted != null)
          TextButton(
            onPressed: uploading.active ? null : delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text("Delete"),
          ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(editable ? "Cancel" : "Close"),
        ),
        if (editable)
          TextButton(onPressed: valid ? save : null, child: Text("Save")),
      ],
      children: [
        TextField(
          controller: nameController,
          enabled: editable,
          autofocus: true,
          decoration: .new(labelText: "Name"),
        ),
        ListTile(
          enabled: editable && !uploading.active,
          leading: Icon(Icons.image),
          title: Text("Avatar"),
          subtitle: Text("The pack's first image if not set."),
          trailing: Row(
            mainAxisSize: .min,
            spacing: 8,
            children: [
              ImagePackAvatar(
                avatar.value ?? images.value.values.firstOrNull?.url,
              ),
              if (avatar.value != null && editable)
                IconButton(
                  tooltip: "Remove avatar",
                  icon: Icon(Icons.delete),
                  onPressed: uploading.active
                      ? null
                      : () => avatar.value = null,
                ),
            ],
          ),
          onTap: () =>
              upload((_, image) => avatar.value = image.url).onError(showError),
        ),
        Text("Default usage", style: textTheme.titleSmall),
        ImageUsageChips(
          value: packUsage,
          onChanged: editable
              ? (value) =>
                    usage.value = value.length == ImageUsage.values.length
                    ? const .empty()
                    : value
              : null,
        ),
        Text("Images", style: textTheme.titleSmall),
        if (images.value.isEmpty && !editable) Text("No images"),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...images.value.entries.map(
              (entry) => Tooltip(
                message: ":${entry.key}:",
                child: InkWell(
                  borderRadius: .circular(8),
                  onTap: () => editImage(entry.key, entry.value),
                  child: Padding(
                    padding: .all(4),
                    child: SizedBox.square(
                      dimension: 56,
                      child: MxcEmoji(entry.value.url, label: entry.key),
                    ),
                  ),
                ),
              ),
            ),
            if (editable)
              SizedBox.square(
                dimension: 64,
                child: uploading.active
                    ? Center(child: CircularProgressIndicator())
                    : IconButton(
                        tooltip: "Add image",
                        icon: Icon(Icons.add_photo_alternate),
                        onPressed: () => upload(
                          (filename, image) => editImage(
                            filename
                                .split(".")
                                .first
                                .replaceAll(RegExp(r"[^\w-]"), ""),
                            image,
                            isNew: true,
                          ),
                        ).onError(showError),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
