import "package:freezed_annotation/freezed_annotation.dart";
part "upload_media.freezed.dart";
part "upload_media.g.dart";

@freezed
abstract class UploadMediaRequest with _$UploadMediaRequest {
  const factory UploadMediaRequest({
    required String path,
    required bool encrypted,
    String? filename,
    @Default(false) @JsonKey(name: "voice_message") bool isVoiceMessage,
    @Default(false) bool forceFile,

    // Below params only work if encodeTo is set
    String? encodeTo,
    int? resizeWidth,
    int? resizeHeight,
    int? resizePercent,
    @Default(80) int quality,
  }) = _UploadMediaRequest;

  factory UploadMediaRequest.fromJson(Map<String, Object?> json) =>
      _$UploadMediaRequestFromJson(json);
}
