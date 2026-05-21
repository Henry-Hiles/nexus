import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/ms_duration.dart";
part "video.freezed.dart";
part "video.g.dart";

@freezed
abstract class VideoInfo with _$VideoInfo {
  /// Information for images, [size] is in bytes.
  const factory VideoInfo({
    @JsonKey(name: "h") int? height,
    @JsonKey(name: "w") int? width,
    @JsonKey(name: "mimetype") String? mimeType,
    @MSDuration() Duration? duration,
    int? size,
  }) = _VideoInfo;

  factory VideoInfo.fromJson(Map<String, Object?> json) =>
      _$VideoInfoFromJson(json);
}
