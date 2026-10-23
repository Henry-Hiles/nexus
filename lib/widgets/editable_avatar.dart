import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/show_adaptive_menu.dart";
import "package:nexus/helpers/file_dialog_helper.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/message.dart";

/// Shows [child], an avatar, with a button to upload a new one or remove it.
class const EditableAvatar({
  required final Widget child,

  /// Whether there's an avatar to remove.
  required final bool hasAvatar,

  /// Called with the uploaded image, or null when the avatar is removed.
  required final Future<void> Function(Uri? url) onChanged,
  final double dimension = 200,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = Saving.use();
    Future<void> save(Future<void> Function() action) =>
        saving.run(() => action().onError(showError));

    Future<void> pick() async {
      final file = await ref
          .read(FileDialogHelper.provider)
          .pickFile(images: true);
      if (file == null || !context.mounted) return;

      await save(() async {
        final content = await ref
            .read(ClientController.provider.notifier)
            .uploadMedia(.new(path: file.path, encrypt: false));
        if (content case ImageMessageContent(:final url)) {
          await onChanged(url);
        } else {
          throw Exception("The file isn't an image");
        }
      });
    }

    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        children: [
          child,
          if (saving.active) const Center(child: CircularProgressIndicator()),
          Positioned(
            right: dimension * 0.01,
            bottom: dimension * 0.01,
            child: Builder(
              builder: (context) => IconButton.filled(
                tooltip: "Edit avatar",
                icon: Icon(Icons.edit),
                onPressed: saving.active
                    ? null
                    : !hasAvatar
                    ? pick
                    : () => context.showAdaptiveMenu([
                        PopupMenuItem(
                          onTap: pick,
                          child: ListTile(
                            leading: Icon(Icons.upload),
                            title: Text("Upload new avatar"),
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => save(() => onChanged(null)),
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text("Remove avatar"),
                          ),
                        ),
                      ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
