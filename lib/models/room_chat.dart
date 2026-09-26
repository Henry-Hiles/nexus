import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "room_chat.freezed.dart";
part "room_chat.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RoomChat({
  required final IList<Event> timeline,
  required final bool hasMoreForward,
  required final bool hasMoreBackward,
  final HistoricalData? historicalData,
}) with _$RoomChat {
  Map<String, Object?> toJson() => _$RoomChatToJson(this);

  factory RoomChat.fromJson(Map<String, Object?> json) =>
      _$RoomChatFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const HistoricalData({
  required final String start,
  required final String end,
}) with _$HistoricalData {
  Map<String, Object?> toJson() => _$HistoricalDataToJson(this);

  factory HistoricalData.fromJson(Map<String, Object?> json) =>
      _$HistoricalDataFromJson(json);
}
