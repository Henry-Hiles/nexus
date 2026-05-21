import "package:freezed_annotation/freezed_annotation.dart";
part "image.freezed.dart";
part "image.g.dart";

@freezed
abstract class ImageInfo with _$ImageInfo {
  /// Information for images, [size] is in bytes.
  const factory ImageInfo({
    @JsonKey(name: "h") double? height,
    @JsonKey(name: "w") double? width,
    @JsonKey(name: "mimetype") String? mimeType,
    @JsonKey(name: "xyz.amorgan.blurhash") String? blurHash,
    int? size,
  }) = _ImageInfo;

  factory ImageInfo.fromJson(Map<String, Object?> json) =>
      _$ImageInfoFromJson(json);
}
