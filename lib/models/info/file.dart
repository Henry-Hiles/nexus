import "package:freezed_annotation/freezed_annotation.dart";
part "file.freezed.dart";
part "file.g.dart";

@freezed
abstract class FileInfo with _$FileInfo {
  /// Information for images, [size] is in bytes.
  const factory FileInfo({
    @JsonKey(name: "mimetype") String? mimeType,
    int? size,
  }) = _FileInfo;

  factory FileInfo.fromJson(Map<String, Object?> json) =>
      _$FileInfoFromJson(json);
}
