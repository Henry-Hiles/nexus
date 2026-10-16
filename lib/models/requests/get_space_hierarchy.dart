import "package:freezed_annotation/freezed_annotation.dart";

part "get_space_hierarchy.freezed.dart";
part "get_space_hierarchy.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const GetSpaceHierarchyRequest({
  required final String roomId,
  final String? from,
  final int limit = 50,
  final int? maxDepth,
  final bool? suggestedOnly,
}) with _$GetSpaceHierarchyRequest {
  Map<String, Object?> toJson() => _$GetSpaceHierarchyRequestToJson(this);

  factory GetSpaceHierarchyRequest.fromJson(Map<String, Object?> json) =>
      _$GetSpaceHierarchyRequestFromJson(json);
}
