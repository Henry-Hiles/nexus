import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "tombstone.freezed.dart";
part "tombstone.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const TombstoneContent({
  final String body = "",
  required final String replacementRoom,
}) extends Content with _$TombstoneContent {
  @override
  Map<String, Object?> toJson() => _$TombstoneContentToJson(this);

  factory TombstoneContent.fromJson(Map<String, Object?> json) =>
      _$TombstoneContentFromJson(json);
}
