import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "emoji.freezed.dart";
part "emoji.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class Emoji({
  required final String emoji,
  required final String category,
  required final IList<String> aliases,
  required final String description,
  required final IList<String> tags,
}) with _$Emoji {
  Map<String, Object?> toJson() => _$EmojiToJson(this);

  factory Emoji.fromJson(Map<String, Object?> json) => _$EmojiFromJson(json);
}
