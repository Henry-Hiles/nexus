import "package:freezed_annotation/freezed_annotation.dart";

part "deregister_pusher.freezed.dart";
part "deregister_pusher.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const DeregisterPusherRequest({
  required final String appId,
  @JsonKey(name: "pushkey") required final String pushKey,
}) with _$DeregisterPusherRequest {
  Map<String, Object?> toJson() => _$DeregisterPusherRequestToJson(this);
}
