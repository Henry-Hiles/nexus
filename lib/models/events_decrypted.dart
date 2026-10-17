import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

part "events_decrypted.freezed.dart";
part "events_decrypted.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const EventsDecrypted({
  required final String roomId,
  @JsonKey(name: "preview_event_rowid") final int? previewEventRowID,
  @EpochDateTimeConverter() final DateTime? sortingTimestamp,

  /// [events] is an IMap of eventRowId to event
  @JsonKey(fromJson: Room.eventsJsonToIMap)
  required final IMap<int, Event> events,
}) with _$EventsDecrypted {
  factory EventsDecrypted.fromJson(Map<String, Object?> json) =>
      _$EventsDecryptedFromJson(json);
}
