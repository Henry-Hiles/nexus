import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room_metadata.dart";
part "room.freezed.dart";
part "room.g.dart";

@freezed
abstract class Room with _$Room {
  static IMap<int, int?> timelineTupleJsonToIMap(List<dynamic> json) =>
      IMap.fromEntries(
        json.map(
          (timelineTuple) => MapEntry(
            timelineTuple["timeline_rowid"],
            timelineTuple["event_rowid"],
          ),
        ),
      );

  static IMap<int, Event> eventsJsonToIMap(List<dynamic> json) =>
      IMap.fromEntries(
        json.map((eventJson) {
          final event = Event.fromJson(eventJson);
          return MapEntry(event.rowId, event);
        }),
      );

  /// [timeline] is an IMap of timelineRowId to eventRowId
  /// [events] is an IMap of eventRowId to event
  /// [sticky] is an ISet of eventRowId
  const factory Room({
    @JsonKey(name: "meta") RoomMetadata? metadata,
    @Default(IMap.empty())
    @JsonKey(fromJson: Room.timelineTupleJsonToIMap)
    IMap<int, int?> timeline,
    @Default(ISet.empty()) ISet<int> sticky,

    @Default(IMap.empty())
    @JsonKey(fromJson: Room.eventsJsonToIMap)
    IMap<int, Event> events,

    @Default(false) bool reset,
    @Default(false) bool hasFetchedState,
    @Default(false) bool hasFetchedMembers,
    @Default(IMap.empty()) IMap<String, IMap<String, int>> state,

    @Default(IMap.empty()) IMap<String, IList<ReadReceipt>> receipts,
    @Default(false) bool dismissNotifications,
    @Default(true) bool hasMore,

    // required IMap<String, AccountData> accountData,
    // required IList<Notification> notifications,
  }) = _Room;

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}
