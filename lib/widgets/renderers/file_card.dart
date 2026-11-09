import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/save_attachment.dart";
import "package:nexus/helpers/extensions/size_to_string.dart";
import "package:nexus/models/info/file.dart";

final class const FileCard(
  final Uri uri,
  final FileInfo? info, {
  final String? filename,
  final bool encrypted = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: 320,
    child: Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading: Icon(Icons.file_copy),
        title: Text(filename ?? "file", maxLines: 1, overflow: .ellipsis),
        subtitle: info?.size == null ? null : Text(info!.size!.sizeAsString),
        trailing: IconButton(
          onPressed: () => context.saveAttachment(
            ref,
            uri,
            encrypted: encrypted,
            filename: filename,
          ),
          icon: Icon(Icons.download),
        ),
      ),
    ),
  );
}
