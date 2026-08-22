import "package:freezed_annotation/freezed_annotation.dart";

part "oauth_auth_code_response.freezed.dart";
part "oauth_auth_code_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const OAuthAuthCodeResponse({
  required final String state,
  required final String codeVerifier,
  required final Uri url,
}) with _$OAuthAuthCodeResponse {
  Map<String, Object?> toJson() => _$OAuthAuthCodeResponseToJson(this);

  factory OAuthAuthCodeResponse.fromJson(Map<String, Object?> json) =>
      _$OAuthAuthCodeResponseFromJson(json);
}
