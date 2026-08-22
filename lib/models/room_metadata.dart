import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/lazy_load_summary.dart";

part "room_metadata.freezed.dart";
part "room_metadata.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RoomMetadata({
  @JsonKey(name: "room_id") required final String id,

  // CreateEventContent creationContent,
  // TombstoneEventContent tombstoneEventContent,
  final String? name,
  final Uri? avatar,
  final String? dmUserId,
  final String? topic,
  final String? canonicalAlias,
  final LazyLoadSummary? lazyLoadSummary,
  required final bool hasMemberList,
  @JsonKey(name: "preview_event_rowid") required final int previewEventRowID,
  @EpochDateTimeConverter() required final DateTime sortingTimestamp,
  required final int unreadHighlights,
  required final int unreadNotifications,
  required final int unreadMessages,
}) with _$RoomMetadata {
  Map<String, Object?> toJson() => _$RoomMetadataToJson(this);

  factory RoomMetadata.fromJson(Map<String, Object?> json) =>
      _$RoomMetadataFromJson(json);
}
