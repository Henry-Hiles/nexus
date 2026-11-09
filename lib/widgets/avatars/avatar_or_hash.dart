import "package:color_hash/color_hash.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/mxc_image.dart";

final class const AvatarOrHash(
  final Uri? avatar,
  final String title, {
  final Widget? fallback,
  final double dimension = 24,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ColoredBox(
      color: ColorHash(title).color,
      child: Center(child: Icon(Icons.person, size: dimension / 2)),
    );

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Center(
        child: ClipRRect(
          borderRadius: .all(.circular((dimension - 8) / 2.5)),
          child: SizedBox.square(
            dimension: dimension,
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
