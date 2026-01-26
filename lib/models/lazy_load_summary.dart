import "package:freezed_annotation/freezed_annotation.dart";
part "lazy_load_summary.freezed.dart";
part "lazy_load_summary.g.dart";

@freezed
abstract class LazyLoadSummary with _$LazyLoadSummary {
  const factory LazyLoadSummary({
    required List<String> heroes,
    required int? joinedMemberCount,
    required int? invitedMemberCount,
  }) = _LazyLoadSummary;

  factory LazyLoadSummary.fromJson(Map<String, Object?> json) =>
      _$LazyLoadSummaryFromJson(json);
}
