import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "encrypted.freezed.dart";
part "encrypted.g.dart";

@freezed
abstract class EncryptedContent extends Content with _$EncryptedContent {
  EncryptedContent._();
  factory EncryptedContent() = _EncryptedContent;

  factory EncryptedContent.fromJson(Map<String, Object?> json) =>
      _$EncryptedContentFromJson(json);
}
