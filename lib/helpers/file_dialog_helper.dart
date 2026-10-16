import "dart:io";

import "package:file_selector/file_selector.dart";
import "package:flutter_file_dialog/flutter_file_dialog.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:mime/mime.dart";
import "package:nexus/controllers/image_picker.dart";
import "package:nexus/controllers/portal.dart";
import "package:xdg_desktop_portal/xdg_desktop_portal.dart";

class FileDialogHelper(final Ref ref) {
  Future<bool> saveFile(File file, String filename) async {
    final mimeType = lookupMimeType(
      file.path,
      headerBytes: await file
          .openRead(0, defaultMagicNumbersMaxLength)
          .expand((bytes) => bytes)
          .toList(),
    );

    final filenameWithExtension = mimeType == null
        ? filename
        : "$filename.${extensionFromMime(mimeType)}";

    if (Platform.isAndroid || Platform.isIOS) {
      return await FlutterFileDialog.saveFile(
            params: .new(
              sourceFilePath: file.path,
              fileName: filenameWithExtension,
            ),
          ) !=
          null;
    }

    final destination = Platform.isLinux
        ? await getLinuxSaveLocation(filenameWithExtension)
        : (await getSaveLocation(suggestedName: filenameWithExtension))?.path;
    if (destination == null) return false;

    await file.copy(destination);
    return true;
  }

  Future<String?> getLinuxSaveLocation(String filename) async {
    final portal = await ref.read(PortalController.provider.future);

    try {
      final result = await portal.fileChooser
          .saveFile(title: "Save file", currentName: filename)
          .first;

      return switch (result.uris.firstOrNull) {
        final uri? => Uri.parse(uri).toFilePath(),
        null => null,
      };
    } on XdgPortalRequestCancelledException catch (_) {
      return null;
    }
  }

  /// Lets the user pick a file, or only images if [images] is true. Returns
  /// null if the user cancelled.
  Future<XFile?> pickFile({bool images = false}) async {
    if (!Platform.isLinux) {
      return images
          ? ref.read(ImagePickerController.provider).pickImage(source: .gallery)
          : openFile();
    }

    final portal = await ref.read(PortalController.provider.future);

    try {
      final result = await portal.fileChooser
          .openFile(
            title: images ? "Pick image" : "Pick file",
            filters: [
              if (images)
                .new("Images", [XdgFileChooserMimeTypePattern("image/*")]),
            ],
          )
          .first;

      return switch (result.uris.firstOrNull) {
        final uri? => XFile(Uri.parse(uri).toFilePath()),
        null => null,
      };
    } on XdgPortalRequestCancelledException catch (_) {
      return null;
    }
  }

  static final provider = Provider<FileDialogHelper>(FileDialogHelper.new);
}
