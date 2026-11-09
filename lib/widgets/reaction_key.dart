import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/mxc_image.dart";

/// A reaction's key, either an emoji or a custom (mxc) image.
class const ReactionKey(
  final String reaction, {
  required final double height,
  final TextStyle? style,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      reaction.startsWith("mxc://")
      ? Image(
          height: height,
          image: MxcImage(ref, .new(mxc: Uri.parse(reaction))),
          errorBuilder: (context, _, _) => Icon(
            Icons.broken_image,
            size: height,
            color: Theme.of(context).colorScheme.error,
          ),
        )
      : Text(reaction, style: style, overflow: .ellipsis);
}
