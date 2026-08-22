import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/read_receipt.dart";
import "package:nexus/models/room_metadata.dart";

part "room.freezed.dart";
part "room.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Room({
  @JsonKey(name: "meta") final RoomMetadata? metadata,

  @JsonKey(fromJson: Room.timelineTupleJsonToIMap)
  final IMap<int, int?> timeline = const IMap.empty(),

  final ISet<int> sticky = const ISet.empty(),

  @JsonKey(fromJson: Room.eventsJsonToIMap)
  final IMap<int, Event> events = const IMap.empty(),

  final bool reset = false,
  final bool hasFetchedState = false,
  final bool hasFetchedMembers = false,
  final IMap<String, IMap<String, int>> state = const IMap.empty(),

  final IMap<String, IList<ReadReceipt>> receipts = const IMap.empty(),
  final bool dismissNotifications = false,
  final bool hasMore = true,

  // IMap<String, AccountData> accountData,
  // IList<Notification> notifications,
}) with _$Room {
  /// [timeline] is an IMap of timelineRowId to eventRowId
  /// [events] is an IMap of eventRowId to event
  /// [sticky] is an ISet of eventRowId
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

  Map<String, Object?> toJson() => _$RoomToJson(this);

  factory Room.fromJson(Map<String, Object?> json) => _$RoomFromJson(json);
}
