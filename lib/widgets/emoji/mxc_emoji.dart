import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/mxc_image.dart";

/// A custom emoji or sticker from an image pack, scaled to fit its parent.
class const MxcEmoji(final Uri url, {final String? label, super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Image(
    image: MxcImage(ref, .new(mxc: url)),
    semanticLabel: label,
    fit: .contain,
    errorBuilder: (context, _, _) =>
        Icon(Icons.broken_image, color: Theme.of(context).colorScheme.error),
  );
}
