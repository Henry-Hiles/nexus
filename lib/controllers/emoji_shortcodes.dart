import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";

/// Maps each unicode emoji, without variation selectors, to its shortcode.
class EmojiShortcodesController extends Notifier<IMap<String, String>> {
  static final _variationSelectors = RegExp("[\uFE0E\uFE0F]");

  static String normalize(String emoji) =>
      emoji.replaceAll(_variationSelectors, "");

  @override
  IMap<String, String> build() => .fromEntries(
    ref
        .watch(EmojiController.provider)
        .requireValue
        .map((category) => category.emojis)
        .flattened
        .where((emoji) => emoji.aliases.isNotEmpty)
        .map(
          (emoji) =>
              MapEntry(normalize(emoji.value), ":${emoji.aliases.first}:"),
        ),
  );

  static final provider =
      NotifierProvider<EmojiShortcodesController, IMap<String, String>>(
        EmojiShortcodesController.new,
      );
}
