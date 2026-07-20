import "package:freezed_annotation/freezed_annotation.dart";
part "oauth_auth_code_response.freezed.dart";
part "oauth_auth_code_response.g.dart";

@freezed
abstract class OAuthAuthCodeResponse with _$OAuthAuthCodeResponse {
  const factory OAuthAuthCodeResponse({
    required String state,
    required String codeVerifier,
    required Uri url,
  }) = _OAuthAuthCodeResponse;

  factory OAuthAuthCodeResponse.fromJson(Map<String, Object?> json) =>
      _$OAuthAuthCodeResponseFromJson(json);
}
