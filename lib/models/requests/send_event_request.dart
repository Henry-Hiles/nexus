import "package:freezed_annotation/freezed_annotation.dart";
part "send_event_request.freezed.dart";
part "send_event_request.g.dart";

@freezed
abstract class SendEventRequest with _$SendEventRequest {
  const factory SendEventRequest({
    required String roomId,
    required String type,
    required Map<String, dynamic> content,
    @Default(false) bool disableEncryption,
  }) = _SendEventRequest;

  factory SendEventRequest.fromJson(Map<String, Object?> json) =>
      _$SendEventRequestFromJson(json);
}
