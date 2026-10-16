import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/show_error_snack_bar.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/helpers/file_dialog_helper.dart";

extension SaveAttachment on BuildContext {
  /// Downloads the media at [mxc], displaying a snackbar whilst it's donwnloading,
  /// then lets the user pick where to save it, suggesting [filename].
  Future<void> saveAttachment(
    WidgetRef ref,
    Uri mxc, {
    required bool encrypted,
    String? filename,
  }) async {
    final file = await withProgressSnackbar(
      "Downloading file...",
      () => ref
          .read(ClientController.provider.notifier)
          .downloadMedia(.new(mxc: mxc, encrypted: encrypted)),
    );
    if (file == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(this);
    try {
      await ref
          .read(FileDialogHelper.provider)
          .saveFile(file, filename ?? mxc.pathSegments.last);
    } catch (error) {
      messenger.showErrorSnackBar(error.toString());
    }
  }
}
