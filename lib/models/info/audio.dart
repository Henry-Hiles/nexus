import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/ms_duration.dart";

part "audio.freezed.dart";
part "audio.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const AudioInfo({
  @MSDuration() final Duration? duration,
  @JsonKey(name: "mimetype") final String? mimeType,
  final int? size,
}) with _$AudioInfo {
  Map<String, Object?> toJson() => _$AudioInfoToJson(this);

  factory AudioInfo.fromJson(Map<String, Object?> json) =>
      _$AudioInfoFromJson(json);
}
