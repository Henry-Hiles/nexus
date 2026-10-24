import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "encrypted.freezed.dart";
part "encrypted.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const EncryptedContent() extends Content with _$EncryptedContent {
  @override
  Map<String, Object?> toJson() => _$EncryptedContentToJson(this);

  factory EncryptedContent.fromJson(Map<String, Object?> json) =>
      _$EncryptedContentFromJson(json);
}
