import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "name.freezed.dart";
part "name.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const NameContent({required final String name})
    extends Content
    with _$NameContent {
  @override
  Map<String, Object?> toJson() => _$NameContentToJson(this);

  factory NameContent.fromJson(Map<String, Object?> json) =>
      _$NameContentFromJson(json);
}
