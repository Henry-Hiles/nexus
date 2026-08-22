import "package:freezed_annotation/freezed_annotation.dart";

part "download_media.freezed.dart";
part "download_media.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const DownloadMediaRequest({
  required final Uri mxc,
  final bool encrypted = false,
  final bool isAvatar = false,
  final bool thumbnailAvatar = false,
}) with _$DownloadMediaRequest {
  Map<String, Object?> toJson() => _$DownloadMediaRequestToJson(this);

  factory DownloadMediaRequest.fromJson(Map<String, Object?> json) =>
      _$DownloadMediaRequestFromJson(json);
}
