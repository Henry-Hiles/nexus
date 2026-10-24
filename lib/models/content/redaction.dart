import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "redaction.freezed.dart";
part "redaction.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RedactionContent({final String? reason, final String? redacts})
    extends Content
    with _$RedactionContent {
  factory RedactionContent.fromJson(Map<String, Object?> json) =>
      _$RedactionContentFromJson(json);
}
