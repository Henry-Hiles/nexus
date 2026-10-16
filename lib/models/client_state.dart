import "package:freezed_annotation/freezed_annotation.dart";

part "client_state.freezed.dart";
part "client_state.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ClientState({
  required final bool isInitialized,
  required final bool isLoggedIn,
  required final bool isVerified,
  required final String? userId,
  required final String? deviceId,
  required final String? homeserverUrl,
  final VerificationState verificationState = const .new(),
}) with _$ClientState {
  Map<String, Object?> toJson() => _$ClientStateToJson(this);

  factory ClientState.fromJson(Map<String, Object?> json) =>
      _$ClientStateFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const VerificationState({
  final bool stateChecked = false,
  final bool hasCrossSigning = false,
  @JsonKey(name: "has_ssss") final bool hasSecretStorage = false,
}) with _$VerificationState {
  Map<String, Object?> toJson() => _$VerificationStateToJson(this);

  factory VerificationState.fromJson(Map<String, Object?> json) =>
      _$VerificationStateFromJson(json);
}
