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

  /// The state event the pack is from, for editing it.
  required final ImagePackContent content,
}) with _$ImagePack {
  /// The pack's avatar, or its first image if it has none.
  Uri? get icon => avatar ?? content.images.values.firstOrNull?.url;

  String get imageCountLabel => content.images.length == 1
      ? "1 image"
      : "${content.images.length} images";

  /// The name of a pack without one, from its room's name and state key.
  static String fallbackName(String roomName, String stateKey) =>
      stateKey.isEmpty ? roomName : "$roomName - $stateKey";

  static String emojiMarkdown(
    String shortcode,
    String url, {
    String? description,
  }) =>
      '![:$shortcode:]($url "Emoji: ${switch (description) {
        final description? when description.isNotEmpty => description,
        _ => ":$shortcode:",
      }.replaceAll(r"\", r"\\").replaceAll('"', r'\"')}")';

  factory ImagePack.fromContent(
    ImagePackContent content, {
    required String roomId,
    required String roomName,
    required String stateKey,
  }) => .new(
    id: "$roomId/$stateKey",
    name: content.pack?.displayName ?? fallbackName(roomName, stateKey),
    avatar: content.pack?.avatarUrl,
    emoticons: content.imagesFor(.emoticon),
    stickers: content.imagesFor(.sticker),
    content: content,
  );
}
