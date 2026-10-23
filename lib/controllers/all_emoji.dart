import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";
import "package:nexus/controllers/image_packs.dart";
import "package:nexus/helpers/extensions/image_pack_emoji.dart";

class AllEmojiController(final String roomId)
    extends AsyncNotifier<IList<EmojiCategory>> {
  @override
  Future<IList<EmojiCategory>> build() async {
    final packs = await ref.watch(ImagePacksController.provider(roomId).future);
    final unicode = await ref.watch(EmojiController.provider.future);

    return packs
        .map((pack) => pack.emojiCategory)
        .nonNulls
        .toIList()
        .addAll(unicode);
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<AllEmojiController, IList<EmojiCategory>, String>(
        AllEmojiController.new,
      );
}
