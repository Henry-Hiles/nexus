import "package:freezed_annotation/freezed_annotation.dart";
part "download_media.freezed.dart";
part "download_media.g.dart";

@freezed
abstract class DownloadMediaRequest with _$DownloadMediaRequest {
  const factory DownloadMediaRequest({
    required Uri mxc,
    @Default(false) bool encrypted,
    @Default(false) bool isAvatar,
    @Default(false) bool thumbnailAvatar,
  }) = _DownloadMediaRequest;

  factory DownloadMediaRequest.fromJson(Map<String, Object?> json) =>
      _$DownloadMediaRequestFromJson(json);
}
