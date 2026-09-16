import "dart:async";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart" as upstream;
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/helpers/extensions/better_when.dart";

class const EmojiPicker({
  required final FutureOr<void> Function(String value) onSelection,
  final bool allowFreeText = false,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(upstream.EmojiController.provider)
      .betterWhen(
        data: (categories) => upstream.EmojiPicker(
          onSelection: (value) async {
            //
            await onSelection(value);
          },
          allowFreeText: allowFreeText,
          prependCategories: .new([
            .new(
              icon: Icon(Icons.history),
              name: "Recent",
              emojis: .new(
                ref
                    .watch(
                      AccountDataController.provider.select(
                        (value) => value.recentEmoji
                            .map((entry) => entry.emoji)
                            .toIList(),
                      ),
                    )
                    .map(
                      (emoji) => categories
                          .map((element) => element.emojis)
                          .flattened
                          .firstWhereOrNull(
                            (element) => element.value == emoji,
                          ),
                    )
                    .nonNulls,
              ),
            ),
          ]),
        ),
      );
}
