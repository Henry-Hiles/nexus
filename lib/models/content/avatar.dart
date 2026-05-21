import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/image.dart";
part "avatar.freezed.dart";
part "avatar.g.dart";

@freezed
abstract class AvatarContent extends Content with _$AvatarContent {
  AvatarContent._();
  factory AvatarContent({ImageInfo? info, Uri? url}) = _AvatarContent;

  factory AvatarContent.fromJson(Map<String, Object?> json) =>
      _$AvatarContentFromJson(json);
}
