import "package:color_hash/color_hash.dart";
import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";

class AvatarOrHash extends ConsumerWidget {
  final Uri? avatar;
  final String title;
  final Widget? fallback;
  final double height;
  const AvatarOrHash(
    this.avatar,
    this.title, {
    this.fallback,
    this.height = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ColoredBox(
      color: ColorHash(title).color,
      child: Center(child: Text(title.isEmpty ? "" : title[0])),
    );

    final parsedAvatar = avatar?.mxcToHttps(
      ref.watch(
            ClientStateController.provider.select(
              (value) => value?.homeserverUrl,
            ),
          ) ??
          "",
    );

    return SizedBox(
      width: height,
      height: height,
      child: Center(
        child: ClipRRect(
          borderRadius: .all(.circular((height - 8) / 2.5)),
          child: SizedBox(
            width: height,
            height: height,
            child: parsedAvatar == null
                ? fallback ?? box
                : Image(
                    image: CachedNetworkImage(
                      parsedAvatar.toString(),
                      ref.watch(CrossCacheController.provider),
                      headers: ref.headers,
                    ),
                    fit: .cover,
                    loadingBuilder: (_, child, loadingProgress) =>
                        loadingProgress == null ? child : fallback ?? box,
                    errorBuilder: (_, _, _) => fallback ?? box,
                  ),
          ),
        ),
      ),
    );
  }
}
