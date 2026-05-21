import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "name.freezed.dart";
part "name.g.dart";

@freezed
abstract class NameContent extends Content with _$NameContent {
  NameContent._();
  factory NameContent({required String name}) = _NameContent;

  factory NameContent.fromJson(Map<String, Object?> json) =>
      _$NameContentFromJson(json);
}
