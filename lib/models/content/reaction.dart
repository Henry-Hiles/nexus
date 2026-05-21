import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "reaction.freezed.dart";
part "reaction.g.dart";

@freezed
abstract class ReactionContent extends Content with _$ReactionContent {
  ReactionContent._();
  static String? keyJsonFromJson(Map<dynamic, dynamic> json, String key) =>
      json["m.relates_to"]?["key"];

  factory ReactionContent({
    @JsonKey(readValue: ReactionContent.keyJsonFromJson) String? key,
  }) = _ReactionContent;

  factory ReactionContent.fromJson(Map<String, Object?> json) =>
      _$ReactionContentFromJson(json);
}
