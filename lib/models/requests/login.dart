import "package:freezed_annotation/freezed_annotation.dart";
part "login.freezed.dart";
part "login.g.dart";

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
    required String homeserverUrl,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, Object?> json) =>
      _$LoginRequestFromJson(json);
}
