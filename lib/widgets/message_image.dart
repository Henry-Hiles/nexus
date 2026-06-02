import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_blurhash/flutter_blurhash.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/models/info/image.dart" as i;
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/loading.dart";

class MessageImage extends ConsumerWidget {
  final Uri url;
  final i.ImageInfo? info;
  const MessageImage(this.url, {this.info, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExpandableImage(
    url.toString(),
    child: ClipRRect(
      borderRadius: .all(.circular(8)),
      child: Image(
        image: CachedNetworkImage(
          url.toString(),
          ref.watch(CrossCacheController.provider),
          headers: ref.headers,
        ),
        width: info?.width,
        loadingBuilder: (_, child, loadingProgress) => loadingProgress == null
            ? child
            : switch (info?.blurHash) {
                final blurHash? =>
                  info?.width == null || info?.height == null
                      ? SizedBox(
                          width: 200,
                          height: 200,
                          child: BlurHash(hash: blurHash),
                        )
                      : AspectRatio(
                          aspectRatio: info!.width! / info!.height!,
                          child: SizedBox(
                            width: info!.width,
                            child: BlurHash(hash: blurHash),
                          ),
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
  );
}
