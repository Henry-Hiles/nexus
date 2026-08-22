import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "pinned_events.freezed.dart";
part "pinned_events.g.dart";

@freezed
sealed class PinnedEventsContent extends Content with _$PinnedEventsContent {
  PinnedEventsContent._();
  factory PinnedEventsContent({
    @Default(IList.empty()) @JsonKey(name: "pinned") IList<String> pinnedEvents,
  }) = _PinnedEventsContent;

  factory PinnedEventsContent.fromJson(Map<String, Object?> json) =>
      _$PinnedEventsContentFromJson(json);
}
