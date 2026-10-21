import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "search.freezed.dart";
part "search.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const SearchRequest({
  required final String searchTerm,
  final IList<String> roomIds = const .empty(),
  final int limit = 20,
  final bool sortByTime = true,

  final String? nextBatch,
}) with _$SearchRequest {
  Map<String, Object?> toJson() => _$SearchRequestToJson(this);

  factory SearchRequest.fromJson(Map<String, Object?> json) =>
      _$SearchRequestFromJson(json);
}
