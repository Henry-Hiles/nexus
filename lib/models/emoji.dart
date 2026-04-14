import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "emoji.freezed.dart";
part "emoji.g.dart";

@freezed
abstract class Emoji with _$Emoji {
  const factory Emoji({
    required String emoji,
    required String category,
    required IList<String> aliases,
    required String description,
    required IList<String> tags,
  }) = _Emoji;

  factory Emoji.fromJson(Map<String, Object?> json) => _$EmojiFromJson(json);
}
