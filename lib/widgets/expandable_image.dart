import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/helpers/extensions/save_attachment.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/widgets/error_dialog.dart";

final class const ExpandableImage(
  final DownloadMediaRequest? request, {
  required final Widget child,

  /// If set, a download button is shown, suggesting this filename
  final String? downloadFilename,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: request == null
        ? null
        : () => showDialog(
            context: context,
            builder: (_) => SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: InteractiveViewer(
                        maxScale: 10,
                        child: Image(
                          errorBuilder: (_, error, stackTrace) => ErrorDialog(
                            "Loading failed for ${request?.mxc}\nError: $error",
                            stackTrace,
                          ),
                          image: MxcImage(ref, request!),
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
                                request!.mxc,
                                encrypted: request!.encrypted,
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
          ),
    child: child,
  );
}
