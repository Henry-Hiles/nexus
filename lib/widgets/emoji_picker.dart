import "dart:async";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart" as upstream;
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/all_emoji.dart";
import "package:nexus/controllers/image_packs.dart";
import "package:nexus/controllers/recent_emoji.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/image_pack_emoji.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/image_pack.dart";

class const EmojiPicker({
  required final String roomId,

  required final FutureOr<void> Function(String value, {String? shortcode})
  onSelection,
  final bool allowFreeText = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEmoji = ref.watch(RecentEmojiController.provider);

    return ref
        .watch(AllEmojiController.provider(roomId))
        .betterWhen(
          data: (categories) {
            final allEmoji = categories.expand((category) => category.emojis);
            final customCategories =
                ref
                    .watch(ImagePacksController.provider(roomId))
                    .value
                    ?.map((pack) => pack.emojiCategory)
                    .nonNulls
                    .toIList() ??
                const .empty();

            return upstream.EmojiPicker(
              onSelection: (emoji) async {
                await onSelection(
                  emoji.value,
                  shortcode: emoji.data is PackImage
                      ? emoji.aliases.first
                      : null,
                );

                await ref
                    .read(RecentEmojiController.provider.notifier)
                    .add(emoji.value)
                    .onError(showError);
              },
              onFreeText: allowFreeText ? (text) => onSelection(text) : null,
              prependCategories: IList<upstream.EmojiCategory>([
                .new(
                  icon: Icon(Icons.history),
                  name: "Recent",
                  emojis: .new(
                    recentEmoji
                        .map(
                          (recent) => allEmoji.firstWhereOrNull(
                            (element) => element.value == recent.emoji,
                          ),
                        )
                        .nonNulls,
                  ),
                ),
              ]).addAll(customCategories),
            );
          },
        );
  }
}
