import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/ms_duration.dart";
part "audio.freezed.dart";
part "audio.g.dart";

@freezed
abstract class AudioInfo with _$AudioInfo {
  /// Information for images, [size] is in bytes.
  const factory AudioInfo({
    @MSDuration() Duration? duration,
    @JsonKey(name: "mimetype") String? mimeType,
    int? size,
  }) = _AudioInfo;

  factory AudioInfo.fromJson(Map<String, Object?> json) =>
      _$AudioInfoFromJson(json);
}
