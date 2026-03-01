import "package:freezed_annotation/freezed_annotation.dart";
part "account_data.freezed.dart";
part "account_data.g.dart";

@freezed
abstract class AccountData with _$AccountData {
  const factory AccountData({
    required String userId,
    required String? roomId,
    required String type,
    required dynamic content,
  }) = _AccountData;

  factory AccountData.fromJson(Map<String, Object?> json) =>
      _$AccountDataFromJson(json);
}
