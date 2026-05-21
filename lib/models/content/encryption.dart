import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "encryption.freezed.dart";
part "encryption.g.dart";

@freezed
abstract class EncryptionContent extends Content with _$EncryptionContent {
  EncryptionContent._();
  factory EncryptionContent({
    required String algorithm,

    @JsonKey(name: "rotation_period_ms")
    @Default(604800000)
    int rotationPeriodMS,

    @JsonKey(name: "rotation_period_msgs")
    @Default(100)
    int rotationPeriodMessages,
  }) = _EncryptionContent;

  factory EncryptionContent.fromJson(Map<String, Object?> json) =>
      _$EncryptionContentFromJson(json);
}
