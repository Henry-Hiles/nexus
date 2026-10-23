import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/widgets/mxc_emoji.dart";

extension ImagePackEmoji on ImagePack {
  EmojiCategory? get emojiCategory => _category(emoticons);
  EmojiCategory? get stickerCategory => _category(stickers);

  EmojiCategory? _category(IMap<String, PackImage> images) => images.isEmpty
      ? null
      : .new(
          icon: MxcEmoji(avatar ?? images.values.first.url),
          name: name,
          emojis: images
              .mapTo(
                (shortcode, image) => Emoji(
                  widget: MxcEmoji(image.url, label: shortcode),
                  value: image.url.toString(),
                  aliases: .new([shortcode]),
                  description: image.body ?? shortcode,
                  tags: const .empty(),
                  data: image,
                ),
              )
              .toIList(),
        );
}
