import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:flutter/widgets.dart";
part "emoji.freezed.dart";
part "emoji.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class Emoji({
  @JsonKey(
    fromJson: Emoji.widgetFromJson,
    readValue: Emoji.readWidgetValueFromJson,
  )
  required final Widget widget,
  @JsonKey(name: "emoji") required final String value,
  required final IList<String> aliases,
  required final String description,
  required final IList<String> tags,
}) with _$Emoji {
  static Widget widgetFromJson(String emoji) => Text(emoji);

  static String readWidgetValueFromJson(Map<dynamic, dynamic> json, _) =>
      json["emoji"];
  factory Emoji.fromJson(Map<String, Object?> json) => _$EmojiFromJson(json);
}
