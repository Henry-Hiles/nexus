import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";

part "push_notification.freezed.dart";
part "push_notification.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const PushNotification({
  @EpochDateTimeConverter() required final DateTime timestamp,

  required final String eventId,
  @JsonKey(name: "event_rowid") required final int eventRowId,

  required final String roomId,
  required final String roomName,
  final Uri? roomAvatar,
  final bool isDm = false,

  required final NotificationUser sender,
  required final NotificationUser self,
  final NotificationUser? perMessageProfile,

  required final String text,
  final Uri? image,

  final bool mention = false,
  final bool reply = false,
  final bool sound = false,
}) with _$PushNotification {
  factory PushNotification.fromJson(Map<String, Object?> json) =>
      _$PushNotificationFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const NotificationUser({
  required final String id,
  required final String name,
  final Uri? avatar,
}) with _$NotificationUser {
  factory NotificationUser.fromJson(Map<String, Object?> json) =>
      _$NotificationUserFromJson(json);
}
