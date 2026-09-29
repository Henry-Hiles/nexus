import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "lazy_load_summary.freezed.dart";
part "lazy_load_summary.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const LazyLoadSummary({
  @JsonKey(name: "m.heroes") required final IList<String>? heroes,
  @JsonKey(name: "m.joined_member_count") required final int? joinedMemberCount,
  @JsonKey(name: "m.invited_member_count")
  required final int? invitedMemberCount,
}) with _$LazyLoadSummary {
  Map<String, Object?> toJson() => _$LazyLoadSummaryToJson(this);

  factory LazyLoadSummary.fromJson(Map<String, Object?> json) =>
      _$LazyLoadSummaryFromJson(json);
}
