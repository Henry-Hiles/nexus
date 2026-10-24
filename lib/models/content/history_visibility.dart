import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "history_visibility.freezed.dart";
part "history_visibility.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const HistoryVisibilityContent({
  @JsonKey(unknownEnumValue: HistoryVisibility.unknown)
  required final HistoryVisibility historyVisibility,
}) extends Content with _$HistoryVisibilityContent {
  factory HistoryVisibilityContent.fromJson(Map<String, Object?> json) =>
      _$HistoryVisibilityContentFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum HistoryVisibility { invited, joined, shared, worldReadable, unknown }
