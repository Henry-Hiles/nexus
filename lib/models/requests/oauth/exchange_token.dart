import "package:freezed_annotation/freezed_annotation.dart";

part "exchange_token.freezed.dart";
part "exchange_token.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const OAuthExchangeTokenRequest({
  required final Uri homeserverUrl,
  required final String codeVerifier,
  required final Uri redirectUri,
  required final String code,
  required final String clientId,
}) with _$OAuthExchangeTokenRequest {
  Map<String, Object?> toJson() => _$OAuthExchangeTokenRequestToJson(this);

  factory OAuthExchangeTokenRequest.fromJson(Map<String, Object?> json) =>
      _$OAuthExchangeTokenRequestFromJson(json);
}
