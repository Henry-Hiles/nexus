import "package:freezed_annotation/freezed_annotation.dart";
part "content_uri.freezed.dart";
part "content_uri.g.dart";

@freezed
abstract class ContentUri with _$ContentUri {
  const factory ContentUri({
    required String homeserver,
    required String fileID,
  }) = _ContentUri;

  factory ContentUri.fromJson(Map<String, Object?> json) =>
      _$ContentUriFromJson(json);
}
