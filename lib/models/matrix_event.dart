import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/epoch_date_time_converter.dart";

part "matrix_event.freezed.dart";
part "matrix_event.g.dart";

/// A plain Matrix event, as sent by the server (e.g. stripped invite state).
///
/// Unlike [Event], this isn't stored in the gomuks database, so it has no row
/// IDs or local content.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const MatrixEvent({
  required final String type,
  final String? stateKey,
  final String? sender,
  final String? eventId,
  final String? roomId,
  @JsonKey(name: "origin_server_ts")
  @EpochDateTimeConverter()
  final DateTime? timestamp,
  required final Content content,
}) with _$MatrixEvent {
  factory MatrixEvent.fromJson(Map<String, dynamic> json) =>
      _$MatrixEventFromJson(json)
          .copyWith(content: .fromEventJson(json["content"], json["type"]));
}
