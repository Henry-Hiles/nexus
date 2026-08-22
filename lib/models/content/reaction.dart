import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "reaction.freezed.dart";
part "reaction.g.dart";

@Freezed(toJson: false)
sealed class ReactionContent extends Content with _$ReactionContent {
  ReactionContent._();
  static String? keyJsonFromJson(Map<dynamic, dynamic> json, String key) =>
      json["m.relates_to"]?["key"];

  factory ReactionContent({
    @JsonKey(readValue: ReactionContent.keyJsonFromJson) String? key,
  }) = _ReactionContent;

  @override
  Map<String, dynamic> toJson() => {
    "m.relates_to": {"key": key},
  };

  factory ReactionContent.fromJson(Map<String, Object?> json) =>
      _$ReactionContentFromJson(json);
}
