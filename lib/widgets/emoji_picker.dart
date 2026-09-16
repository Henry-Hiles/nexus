import "dart:async";

import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart" as upstream;
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/recent_emoji.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/main.dart";

class const EmojiPicker({
  required final FutureOr<void> Function(String value) onSelection,
  final bool allowFreeText = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEmoji = ref.watch(RecentEmojiController.provider);

    return ref
        .watch(upstream.EmojiController.provider)
        .betterWhen(
          data: (categories) => upstream.EmojiPicker(
            onSelection: (emoji) async {
              await onSelection(emoji);
              await ref
                  .watch(RecentEmojiController.provider.notifier)
                  .add(emoji)
                  .onError(showError);
            },
            allowFreeText: allowFreeText,
            prependCategories: .new([
              .new(
                icon: Icon(Icons.history),
                name: "Recent",
                emojis: .new(
                  recentEmoji
                      .map(
                        (recent) => categories
                            .map((element) => element.emojis)
                            .flattened
                            .firstWhereOrNull(
                              (element) => element.value == recent.emoji,
                            ),
                      )
                      .nonNulls,
                ),
              ),
            ]),
          ),
        );
  }
}
