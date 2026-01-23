import "package:freezed_annotation/freezed_annotation.dart";
part "client_state.freezed.dart";
part "client_state.g.dart";

@freezed
abstract class ClientState with _$ClientState {
  const factory ClientState({
    required bool isInitialized,
    required bool isLoggedIn,
    required bool isVerified,
  }) = _ClientState;

  factory ClientState.fromJson(Map<String, Object?> json) =>
      _$ClientStateFromJson(json);
}
