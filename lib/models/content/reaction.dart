import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "reaction.freezed.dart";
part "reaction.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ReactionContent({
  @JsonKey(readValue: ReactionContent.keyJsonFromJson) final String? key,

  /// For custom emoji reactions
  @JsonKey(name: "com.beeper.reaction.shortcode") final String? shortcode,
}) extends Content with _$ReactionContent {
  static String? keyJsonFromJson(Map<dynamic, dynamic> json, String key) =>
      json["m.relates_to"]?["key"];

  @override
  Map<String, dynamic> toJson() => {
    "m.relates_to": {"key": key},
    "com.beeper.reaction.shortcode": ?shortcode,
  };

  factory ReactionContent.fromJson(Map<String, Object?> json) =>
      _$ReactionContentFromJson(json);
}
