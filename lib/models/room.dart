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
    required List<TimelineRowTuple> timeline,
    required bool reset,
    required Map<String, Map> state,
    // required Map<String, AccountData> accountData,
    required List<Event> events,
    required Map<String, List<ReadReceipt>> receipts,
    required bool dismissNotifications,
    // required List<Notification> notifications,
  }) = _Room;

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}

@freezed
abstract class TimelineRowTuple with _$TimelineRowTuple {
  const factory TimelineRowTuple({
    @JsonKey(name: "timeline_rowid") required int timelineRowId,
    @JsonKey(name: "timeline_eventid") required int eventRowId,
  }) = _TimelineRowTuple;

  factory TimelineRowTuple.fromJson(Map<String, Object?> json) =>
      _$TimelineRowTupleFromJson(json);
}
