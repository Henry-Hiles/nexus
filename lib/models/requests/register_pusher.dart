import "package:freezed_annotation/freezed_annotation.dart";

part "register_pusher.freezed.dart";
part "register_pusher.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RegisterPusherRequest({
  required final String appDisplayName,
  required final String appId,
  final bool append = false,
  required final PusherData data,
  required final String deviceDisplayName,
  required final PusherKind kind,
  required final String lang,

  /// TODO: What does this do?
  final String? profileTag,

  @JsonKey(name: "pushkey") required final String pushKey,
}) with _$RegisterPusherRequest {
  Map<String, Object?> toJson() => _$RegisterPusherRequestToJson(this);
}

@freezed
sealed class PusherData with _$PusherData {
  const factory PusherData.http({
    required Uri url,
    @Default(PushFormat.eventIdOnly) PushFormat format,
  }) = HttpPusherData;

  const factory PusherData.webPush({
    required Uri url,
    @Default(PushFormat.eventIdOnly) PushFormat format,

    /// `data.auth`: RFC8291 authentication secret.
    required String auth,
  }) = WebPushPusherData;

  factory PusherData.fromJson(Map<String, Object?> json) =>
      _$PusherDataFromJson(json);
}

@JsonEnum(fieldRename: .snake)
enum PushFormat {
  @JsonValue(null)
  all,
  eventIdOnly,
}

enum PusherKind {
  http,
  email,
  @JsonValue("org.matrix.msc4174.webpush")
  webPush,
}
