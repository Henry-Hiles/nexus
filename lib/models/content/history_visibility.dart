import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "history_visibility.freezed.dart";
part "history_visibility.g.dart";

@freezed
abstract class HistoryVisibilityContent extends Content
    with _$HistoryVisibilityContent {
  HistoryVisibilityContent._();
  factory HistoryVisibilityContent({
    required HistoryVisibility historyVisibility,
  }) = _HistoryVisibilityContent;

  factory HistoryVisibilityContent.fromJson(Map<String, Object?> json) =>
      _$HistoryVisibilityContentFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum HistoryVisibility { invited, joined, shared, worldReadable }
