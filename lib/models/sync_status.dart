import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";

part "sync_status.freezed.dart";
part "sync_status.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SyncStatus({
  required final SyncStatusType type,
  required final int errorCount,
  final String? error,
  @EpochDateTimeConverter() final DateTime? lastSync,
}) with _$SyncStatus {
  Map<String, Object?> toJson() => _$SyncStatusToJson(this);

  factory SyncStatus.fromJson(Map<String, Object?> json) =>
      _$SyncStatusFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.kebab)
enum SyncStatusType { ok, waiting, erroring, permanentlyFailed }
