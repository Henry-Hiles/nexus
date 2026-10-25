import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "encryption.freezed.dart";
part "encryption.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const EncryptionContent({
  required final String algorithm,
  @JsonKey(name: "rotation_period_ms") final int rotationPeriodMS = 604800000,
  @JsonKey(name: "rotation_period_msgs") final int rotationPeriodMessages = 100,
}) extends Content with _$EncryptionContent {
  @override
  Map<String, Object?> toJson() => _$EncryptionContentToJson(this);

  factory EncryptionContent.fromJson(Map<String, Object?> json) =>
      _$EncryptionContentFromJson(json);
}
