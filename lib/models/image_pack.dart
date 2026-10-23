import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/image_pack.dart";

part "image_pack.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const ImagePack({
  required final String id,
  required final String name,
  final Uri? avatar,

  /// Map of shortcode to images
  required final IMap<String, PackImage> emoticons,
  required final IMap<String, PackImage> stickers,
}) with _$ImagePack {
  static String emojiMarkdown(String shortcode, String url) {
    final title = ":$shortcode:".replaceAll(r"\", r"\\").replaceAll('"', r'\"');
    return '![:$shortcode:]($url "Emoji: $title")';
  }

  factory ImagePack.fromContent(
    ImagePackContent content, {
    required String id,
    required String fallbackName,
  }) => .new(
    id: id,
    name: content.pack?.displayName ?? fallbackName,
    avatar: content.pack?.avatarUrl,
    emoticons: content.imagesFor(.emoticon),
    stickers: content.imagesFor(.sticker),
  );
}
