import "package:freezed_annotation/freezed_annotation.dart";
part "report_request.freezed.dart";
part "report_request.g.dart";

@freezed
abstract class ReportRequest with _$ReportRequest {
  const factory ReportRequest({
    required String roomId,
    required String eventId,
    String? reason,
  }) = _ReportRequest;

  factory ReportRequest.fromJson(Map<String, Object?> json) =>
      _$ReportRequestFromJson(json);
}
