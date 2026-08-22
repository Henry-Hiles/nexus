import "package:freezed_annotation/freezed_annotation.dart";

part "report.freezed.dart";
part "report.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ReportRequest({
  required final String roomId,
  required final String eventId,
  final String? reason,
}) with _$ReportRequest {
  Map<String, Object?> toJson() => _$ReportRequestToJson(this);

  factory ReportRequest.fromJson(Map<String, Object?> json) =>
      _$ReportRequestFromJson(json);
}
