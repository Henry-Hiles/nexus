import "package:freezed_annotation/freezed_annotation.dart";
part "image_data.freezed.dart";

@freezed
abstract class ImageData with _$ImageData {
  const factory ImageData({
    required String uri,
    required int? height,
    required int? width,
  }) = _ImageData;
}
