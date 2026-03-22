import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room_metadata.dart";
part "room.freezed.dart";
part "room.g.dart";

@freezed
abstract class Room with _$Room {
  const factory Room({
    @JsonKey(name: "meta") RoomMetadata? metadata,
    @Default(IList.empty()) IList<TimelineRowTuple> timeline,
    @Default(false) bool reset,
    @Default(IMap.empty()) IMap<String, IMap<String, int>> state,
    // required IMap<String, AccountData> accountData,
    @Default(IList.empty()) IList<Event> events,
    @Default(IMap.empty()) IMap<String, IList<ReadReceipt>> receipts,
    @Default(false) bool dismissNotifications,
    @Default(true) bool hasMore,
    // required IList<Notification> notifications,
  }) = _Room;

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}

@freezed
abstract class TimelineRowTuple with _$TimelineRowTuple {
  const factory TimelineRowTuple({
    @JsonKey(name: "timeline_rowid") required int timelineRowId,
    @JsonKey(name: "event_rowid") int? eventRowId,
  }) = _TimelineRowTuple;

  factory TimelineRowTuple.fromJson(Map<String, Object?> json) =>
      _$TimelineRowTupleFromJson(json);
}
