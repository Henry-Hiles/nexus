import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "get_auth_url.freezed.dart";
part "get_auth_url.g.dart";

@freezed
abstract class OAuthGetAuthUrl with _$OAuthGetAuthUrl {
  const factory OAuthGetAuthUrl({
    required ResponseMode responseMode,
    required Uri homeserverUrl,
    required Uri redirectUri,
    required IList<String> scopes,
    required String clientId,
    String? userIdHint,
  }) = _OAuthGetAuthUrl;

  factory OAuthGetAuthUrl.fromJson(Map<String, Object?> json) =>
      _$OAuthGetAuthUrlFromJson(json);
}

abstract class Scope {
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
