import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/save_attachment.dart";
import "package:nexus/helpers/extensions/size_to_string.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/widgets/common/error_dialog.dart";

extension ShowImageViewer on BuildContext {
  /// Shows the image from [request] fullscreen, zoomable.
  ///
  /// If [downloadFilename] is set, a download button is shown, suggesting it.
  void showImageViewer(
    WidgetRef ref,
    DownloadMediaRequest request, {
    String? downloadFilename,
    int? size,
  }) => showDialog(
    context: this,
    builder: (context) => SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: Navigator.of(context).pop,
              child: InteractiveViewer(
                maxScale: 10,
                child: Image(
                  errorBuilder: (_, error, stackTrace) => ErrorDialog(
                    "Loading failed for ${request.mxc}\nError: $error",
                    stackTrace,
                  ),
                  image: MxcImage(ref, request),
                ),
              ),
            ),
          ),
          if (size != null)
            Align(
              alignment: .topLeft,
              child: Padding(
                padding: .all(32),
                child: Card(
                  margin: .zero,
                  child: Padding(
                    padding: .symmetric(horizontal: 12, vertical: 8),
                    child: Text(size.sizeAsString),
                  ),
                ),
              ),
            ),
          Align(
            alignment: .topRight,
            child: Padding(
              padding: .all(32),
              child: Row(
                mainAxisSize: .min,
                spacing: 8,
                children: [
                  if (downloadFilename != null)
                    M3EButton(
                      onPressed: () => context.saveAttachment(
                        ref,
                        request.mxc,
                        encrypted: request.encrypted,
                        filename: downloadFilename,
                      ),
                      child: Icon(Icons.download),
                    ),
                  M3EButton(
                    onPressed: Navigator.of(context).pop,
                    child: Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
