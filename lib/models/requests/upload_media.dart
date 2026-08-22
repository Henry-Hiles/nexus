import "package:freezed_annotation/freezed_annotation.dart";

part "upload_media.freezed.dart";
part "upload_media.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const UploadMediaRequest({
  required final String path,
  required final bool encrypt,
  final String? filename,
  @JsonKey(name: "voice_message") final bool isVoiceMessage = false,
  final bool forceFile = false,
  final
  // Below params only work if encodeTo is set
  String?
  encodeTo,
  final int? resizeWidth,
  final int? resizeHeight,
  final int? resizePercent,
  final int quality = 80,
}) with _$UploadMediaRequest {
  Map<String, Object?> toJson() => _$UploadMediaRequestToJson(this);

  factory UploadMediaRequest.fromJson(Map<String, Object?> json) =>
      _$UploadMediaRequestFromJson(json);
}
