import "package:freezed_annotation/freezed_annotation.dart";
part "report.freezed.dart";
part "report.g.dart";

@freezed
abstract class Report with _$Report {
  const factory Report({
    required String roomId,
    required String eventId,
    String? reason,
  }) = _Report;

  factory Report.fromJson(Map<String, Object?> json) => _$ReportFromJson(json);
}
