import "package:freezed_annotation/freezed_annotation.dart";
part "sync_status.freezed.dart";
part "sync_status.g.dart";

@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required SyncStatusType type,
    required int errorCount,
    required int lastSync,
  }) = _SyncStatus;

  factory SyncStatus.fromJson(Map<String, Object?> json) =>
      _$SyncStatusFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum SyncStatusType { ok, waiting, erroring, permanentlyFailed }
