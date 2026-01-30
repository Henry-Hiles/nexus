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
  final bool hasBadge;
  final int badgeNumber;
  final double height;
  const AvatarOrHash(
    this.avatar,
    this.title, {
    this.fallback,
    this.badgeNumber = 0,
    this.hasBadge = false,
    this.height = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ColoredBox(
      color: ColorHash(title).color,
      child: Center(child: Text(title.isEmpty ? "" : title[0])),
    );
    return SizedBox(
      width: height,
      height: height,
      child: Center(
        child: Badge(
          isLabelVisible: hasBadge,
          label: badgeNumber != 0 ? Text(badgeNumber.toString()) : null,
          smallSize: 12,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: SizedBox(
              width: height,
              height: height,
              child: avatar == null
                  ? fallback ?? box
                  : Image(
                      image: CachedNetworkImage(
                        avatar!
                            .mxcToHttps(
                              ref.watch(
                                    ClientStateController.provider.select(
                                      (value) => value?.homeserverUrl,
                                    ),
                                  ) ??
                                  "",
                            )
                            .toString(),
                        ref.watch(CrossCacheController.provider),
                        headers: ref.headers,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => box,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
