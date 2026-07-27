import "package:color_hash/color_hash.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/mxc_image.dart";

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
      child: Center(child: Icon(Icons.person, size: height / 2)),
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
            child: avatar == null
                ? fallback ?? box
                : Image(
                    image: MxcImage(ref, .new(mxc: avatar!, isAvatar: true)),
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
