import "package:freezed_annotation/freezed_annotation.dart";
part "set_account_data.freezed.dart";
part "set_account_data.g.dart";

@freezed
abstract class SetAccountDataRequest with _$SetAccountDataRequest {
  const factory SetAccountDataRequest({
    required String type,
    required dynamic content,
    String? roomId,
  }) = _SetAccountDataRequest;

  factory SetAccountDataRequest.fromJson(Map<String, Object?> json) =>
      _$SetAccountDataRequestFromJson(json);
}
