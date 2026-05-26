import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/image.dart";
part "sticker.freezed.dart";
part "sticker.g.dart";

@freezed
abstract class StickerContent extends Content with _$StickerContent {
  StickerContent._();
  factory StickerContent({
    required String body,
    required ImageInfo info,
    required Uri url,
  }) = _StickerContent;

  factory StickerContent.fromJson(Map<String, Object?> json) =>
      _$StickerContentFromJson(json);
}
