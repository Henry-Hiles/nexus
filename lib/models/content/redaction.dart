import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "redaction.freezed.dart";
part "redaction.g.dart";

@freezed
abstract class RedactionContent extends Content with _$RedactionContent {
  RedactionContent._();
  factory RedactionContent({String? reason, String? redacts}) =
      _RedactionContent;

  factory RedactionContent.fromJson(Map<String, Object?> json) =>
      _$RedactionContentFromJson(json);
}
