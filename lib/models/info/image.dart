import "package:freezed_annotation/freezed_annotation.dart";

part "image.freezed.dart";
part "image.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ImageInfo({
  @JsonKey(name: "h") final double? height,
  @JsonKey(name: "w") final double? width,
  @JsonKey(name: "mimetype") final String? mimeType,
  @JsonKey(name: "xyz.amorgan.blurhash") final String? blurHash,
  final int? size,
}) with _$ImageInfo {
  Map<String, Object?> toJson() => _$ImageInfoToJson(this);

  factory ImageInfo.fromJson(Map<String, Object?> json) =>
      _$ImageInfoFromJson(json);
}
