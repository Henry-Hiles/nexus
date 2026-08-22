import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";

part "read_receipt.freezed.dart";
part "read_receipt.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ReadReceipt({
  final String? roomId,
  required final String userId,
  final String? threadId,
  required final String eventId,
  @EpochDateTimeConverter() required final DateTime timestamp,
}) with _$ReadReceipt {
  Map<String, Object?> toJson() => _$ReadReceiptToJson(this);

  factory ReadReceipt.fromJson(Map<String, Object?> json) =>
      _$ReadReceiptFromJson(json);
}
