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
    required bool reset,
    required IMap<String, IMap> state,
    // required IMap<String, AccountData> accountData,
    required IList<Event> events,
    @Default(IMap.empty()) IMap<String, IList<ReadReceipt>> receipts,
    required bool dismissNotifications,
    // required IList<Notification> notifications,
  }) = _Room;

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}

@freezed
abstract class TimelineRowTuple with _$TimelineRowTuple {
  const factory TimelineRowTuple({
    @JsonKey(name: "timeline_rowid") required int timelineRowId,
    @JsonKey(name: "timeline_eventid") int? eventRowId,
  }) = _TimelineRowTuple;

  factory TimelineRowTuple.fromJson(Map<String, Object?> json) =>
      _$TimelineRowTupleFromJson(json);
}
