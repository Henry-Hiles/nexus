import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/ms_duration.dart";

part "video.freezed.dart";
part "video.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const VideoInfo({
  @JsonKey(name: "h") final int? height,
  @JsonKey(name: "w") final int? width,
  @JsonKey(name: "mimetype") final String? mimeType,
  @MSDuration() final Duration? duration,
  final int? size,
}) with _$VideoInfo {
  Map<String, Object?> toJson() => _$VideoInfoToJson(this);

  factory VideoInfo.fromJson(Map<String, Object?> json) =>
      _$VideoInfoFromJson(json);
}
