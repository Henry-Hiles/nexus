import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "register_client.freezed.dart";
part "register_client.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const OAuthRegisterClientRequest({
  required final Uri homeserverUrl,
  final ApplicationType applicationType = ApplicationType.web,
  final String? clientName,
  required final Uri clientUri,
  final Uri? logoUri,
  final Uri? policyUri,
  final Uri? tosUri,
  final IList<GrantType>? grantTypes,
  final IList<Uri>? redirectUris,
  final IList<ResponseType>? responseTypes,

  @JsonKey(name: "token_endpoint_auth_method")
  final AuthMethod? authMethod = AuthMethod.none,
}) with _$OAuthRegisterClientRequest {
  Map<String, Object?> toJson() => _$OAuthRegisterClientRequestToJson(this);

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
