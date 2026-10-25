import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/image.dart";
part "avatar.freezed.dart";
part "avatar.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const AvatarContent({final ImageInfo? info, final Uri? url})
    extends Content
    with _$AvatarContent {
  @override
  Map<String, Object?> toJson() => _$AvatarContentToJson(this);

  factory AvatarContent.fromJson(Map<String, Object?> json) =>
      _$AvatarContentFromJson(json);
}
