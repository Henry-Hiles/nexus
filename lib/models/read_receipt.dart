import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
part "read_receipt.freezed.dart";
part "read_receipt.g.dart";

@freezed
abstract class ReadReceipt with _$ReadReceipt {
  const factory ReadReceipt({
    String? roomId,
    required String userId,
    String? threadId,
    required String eventId,
    @EpochDateTimeConverter() required DateTime timestamp,
  }) = _ReadReceipt;

  factory ReadReceipt.fromJson(Map<String, Object?> json) =>
      _$ReadReceiptFromJson(json);
}
