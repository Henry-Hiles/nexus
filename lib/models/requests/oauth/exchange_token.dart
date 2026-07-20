import "package:freezed_annotation/freezed_annotation.dart";
part "exchange_token.freezed.dart";
part "exchange_token.g.dart";

@freezed
abstract class OAuthExchangeTokenRequest with _$OAuthExchangeTokenRequest {
  const factory OAuthExchangeTokenRequest({
    required Uri homeserverUrl,
    required String codeVerifier,
    required Uri redirectUri,
    required String code,
    required String clientId,
  }) = _OAuthExchangeTokenRequest;

  factory OAuthExchangeTokenRequest.fromJson(Map<String, Object?> json) =>
      _$OAuthExchangeTokenRequestFromJson(json);
}
