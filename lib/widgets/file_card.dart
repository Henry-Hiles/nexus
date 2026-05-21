import "package:flutter/material.dart";
import "package:nexus/helpers/extensions/size_to_string.dart";
import "package:nexus/models/info/file.dart";

class FileCard extends StatelessWidget {
  final Uri uri;
  final FileInfo? info;
  final String? filename;
  const FileCard(this.uri, this.info, {this.filename, super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading: Icon(Icons.file_copy),
        title: Text(
          filename ?? "file",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: info?.size == null ? null : Text(info!.size!.sizeAsString),
        // TODO: Downloading files
        trailing: IconButton(onPressed: null, icon: Icon(Icons.download)),
      ),
    ),
  );
}
