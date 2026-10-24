import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "pinned_events.freezed.dart";
part "pinned_events.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PinnedEventsContent({
  @JsonKey(name: "pinned") final IList<String> pinnedEvents = const .empty(),
}) extends Content with _$PinnedEventsContent {
  factory PinnedEventsContent.fromJson(Map<String, Object?> json) =>
      _$PinnedEventsContentFromJson(json);
}
