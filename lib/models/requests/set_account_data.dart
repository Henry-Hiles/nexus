import "package:freezed_annotation/freezed_annotation.dart";

part "set_account_data.freezed.dart";
part "set_account_data.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SetAccountDataRequest({
  required final String type,
  required final dynamic content,
  final String? roomId,
}) with _$SetAccountDataRequest {
  Map<String, Object?> toJson() => _$SetAccountDataRequestToJson(this);

  factory SetAccountDataRequest.fromJson(Map<String, Object?> json) =>
      _$SetAccountDataRequestFromJson(json);
}
