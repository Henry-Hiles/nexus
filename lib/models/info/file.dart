import "package:freezed_annotation/freezed_annotation.dart";

part "file.freezed.dart";
part "file.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const FileInfo({
  @JsonKey(name: "mimetype") final String? mimeType,
  final int? size,
}) with _$FileInfo {
  Map<String, Object?> toJson() => _$FileInfoToJson(this);

  factory FileInfo.fromJson(Map<String, Object?> json) =>
      _$FileInfoFromJson(json);
}
