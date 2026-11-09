import "dart:async";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/image_packs.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/image_pack_emoji.dart";
import "package:nexus/models/content/image_pack.dart";

/// Stickers from the image packs available in [roomId], grouped by pack.
class const StickerPicker({
  required final String roomId,
  required final FutureOr<void> Function(String shortcode, PackImage image)
  onSelection,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(ImagePacksController.provider(roomId))
      .betterWhen(
        data: (packs) {
          final categories = packs
              .map((pack) => pack.stickerCategory)
              .nonNulls
              .toIList();

          return categories.isEmpty
              ? Padding(
                  padding: .all(16),
                  child: Center(child: Text("No sticker packs available")),
                )
              : EmojiPicker(
                  prependCategories: categories,
                  includeDefaultEmoji: false,
                  itemSize: 96,
                  searchHint: "Search stickers",
                  onSelection: (sticker) {
                    if (sticker.data case final PackImage image) {
                      return onSelection(sticker.aliases.first, image);
                    }
                  },
                );
        },
      );
}
