import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/lazy_load_summary.dart";
part "room_metadata.freezed.dart";
part "room_metadata.g.dart";

@freezed
abstract class RoomMetadata with _$RoomMetadata {
  const factory RoomMetadata({
    @JsonKey(name: "room_id") required String id,

    // required CreateEventContent creationContent,
    // required TombstoneEventContent tombstoneEventContent,
    String? name,
    Uri? avatar,
    String? dmUserId,
    String? topic,
    String? canonicalAlias,
    LazyLoadSummary? lazyLoadSummary,
    required bool hasMemberList,
    @JsonKey(name: "preview_event_rowid") required int previewEventRowID,
    @EpochDateTimeConverter() required DateTime sortingTimestamp,
    required int unreadHighlights,
    required int unreadNotifications,
    required int unreadMessages,
  }) = _RoomMetadata;

  factory RoomMetadata.fromJson(Map<String, Object?> json) =>
      _$RoomMetadataFromJson(json);
}
