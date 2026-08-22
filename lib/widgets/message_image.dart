import "package:material_ui/material_ui.dart";
import "package:flutter_blurhash/flutter_blurhash.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/models/info/image.dart" as i;
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/loading.dart";

final class const MessageImage(
  final Uri url, {
  final i.ImageInfo? info,
  required final bool encrypted,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DownloadMediaRequest(mxc: url, encrypted: encrypted);
    return ExpandableImage(
      request,
      child: ClipRRect(
        borderRadius: .all(.circular(8)),
        child: AspectRatio(
          aspectRatio: (info?.width ?? 1) / (info?.height ?? 1),
          child: Image(
            image: MxcImage(ref, request),
            width: info?.width,
            fit: BoxFit.fitWidth,
            loadingBuilder: (_, child, loadingProgress) =>
                loadingProgress == null
                ? child
                : switch (info?.blurHash) {
                    final blurHash? =>
                      info?.width == null || info?.height == null
                          ? SizedBox(
                              width: 200,
                              height: 200,
                              child: BlurHash(hash: blurHash),
                            )
                          : SizedBox(
                              width: info!.width,
                              child: BlurHash(hash: blurHash),
                            ),
                    _ => Loading(),
                  },
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                "Image Failed to Load",
                style: .new(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
