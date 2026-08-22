import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";

part "send_event.freezed.dart";
part "send_event.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SendEventRequest({
  required final String roomId,
  required final String type,
  required final Content content,
  final String? relatesTo,
  final String? relationType,
  final bool synchronous = false,
  final bool disableEncryption = false,
}) with _$SendEventRequest {
  Map<String, Object?> toJson() => _$SendEventRequestToJson(this);

  factory SendEventRequest.fromJson(Map<String, Object?> json) =>
      _$SendEventRequestFromJson(json);
}
