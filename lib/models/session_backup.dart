import "package:freezed_annotation/freezed_annotation.dart";
part "session_backup.freezed.dart";
part "session_backup.g.dart";

@freezed
abstract class SessionBackup with _$SessionBackup {
  const factory SessionBackup({
    required String accessToken,
    required Uri homeserver,
    required String userID,
    required String deviceID,
    required String deviceName,
  }) = _SessionBackup;

  factory SessionBackup.fromJson(Map<String, Object?> json) =>
      _$SessionBackupFromJson(json);
}
