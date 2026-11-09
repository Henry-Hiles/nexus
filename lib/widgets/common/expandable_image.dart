import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/helpers/extensions/show_image_viewer.dart";
import "package:nexus/models/requests/download_media.dart";

final class const ExpandableImage(
  final DownloadMediaRequest? request, {
  required final Widget child,

  /// If set, a download button is shown, suggesting this filename
  final String? downloadFilename,
  final int? size,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: switch (request) {
      final request? => () => context.showImageViewer(
        ref,
        request,
        downloadFilename: downloadFilename,
        size: size,
      ),
      null => null,
    },
    child: child,
  );
}
