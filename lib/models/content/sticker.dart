import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/image.dart";
part "sticker.freezed.dart";
part "sticker.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const StickerContent({
  required final String body,
  required final ImageInfo info,
  required final Uri url,
}) extends Content with _$StickerContent {
  factory StickerContent.fromJson(Map<String, Object?> json) =>
      _$StickerContentFromJson(json);
}
