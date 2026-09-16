import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/emoji.dart";
import "package:flutter/widgets.dart";
part "emoji_category.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class EmojiCategory({
  required final Widget icon,
  required final String name,
  required final IList<Emoji> emojis,
}) with _$EmojiCategory;
