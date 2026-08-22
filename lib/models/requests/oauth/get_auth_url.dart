import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "get_auth_url.freezed.dart";
part "get_auth_url.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const OAuthGetAuthUrl({
  required final ResponseMode responseMode,
  required final Uri homeserverUrl,
  required final Uri redirectUri,
  required final IList<String> scopes,
  required final String clientId,
  final String? userIdHint,
}) with _$OAuthGetAuthUrl {
  Map<String, Object?> toJson() => _$OAuthGetAuthUrlToJson(this);

  factory OAuthGetAuthUrl.fromJson(Map<String, Object?> json) =>
      _$OAuthGetAuthUrlFromJson(json);
}

sealed class Scope {
  static final openid = "openid";
  static final email = "email";
  static final clientApi = "urn:matrix:client:api:*";

  static final _deviceChars = IList(
    ("ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "abcdefghijklmnopqrstuvwxyz"
            "0123456789"
            "-._~")
        .split(""),
  );

  static String get _deviceId =>
      _deviceChars.shuffle(Random.secure()).sublist(0, 10).join();

  static String get device => "urn:matrix:client:device:$_deviceId";
}

@JsonEnum(fieldRename: .snake)
enum ResponseMode { query, fragment }
