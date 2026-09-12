import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/event.dart";
part "get_mentions.freezed.dart";
part "get_mentions.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class GetMentionsRequest({
  @EpochDateTimeConverter() required final DateTime maxTimestamp,
  @JsonKey(name: "type") required final UnreadType unreadType,
  required final int limit,
  final String? roomId,
}) with _$GetMentionsRequest {
  Map<String, Object?> toJson() => _$GetMentionsRequestToJson(this);

  factory GetMentionsRequest.fromJson(Map<String, Object?> json) =>
      _$GetMentionsRequestFromJson(json);
}
