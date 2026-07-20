import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "register_client.freezed.dart";
part "register_client.g.dart";

@freezed
abstract class OAuthRegisterClientRequest with _$OAuthRegisterClientRequest {
  const factory OAuthRegisterClientRequest({
    required Uri homeserverUrl,
    @Default(ApplicationType.web) ApplicationType applicationType,
    String? clientName,
    required Uri clientUri,
    Uri? logoUri,
    Uri? policyUri,
    Uri? tosUri,
    IList<GrantType>? grantTypes,
    IList<Uri>? redirectUris,
    IList<ResponseType>? responseTypes,
    AuthMethod? authMethod,
  }) = _OAuthRegisterClientRequest;

  factory OAuthRegisterClientRequest.fromJson(Map<String, Object?> json) =>
      _$OAuthRegisterClientRequestFromJson(json);
}

enum ApplicationType { native, web }

@JsonEnum(fieldRename: .snake)
enum ResponseType { code, idToken }

@JsonEnum(fieldRename: .snake)
enum AuthMethod {
  clientSecretPost,
  clientSecretBasic,
  clientSecretJwt,
  privateKeyJwt,
  none,
}

@JsonEnum(fieldRename: .snake)
enum GrantType {
  authorizationCode,
  refreshToken,
  clientCredentials,
  @JsonValue("urn:ietf:params:oauth:grant-type:device_code")
  deviceCode,
}
