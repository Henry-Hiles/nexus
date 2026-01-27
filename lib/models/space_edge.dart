import "package:freezed_annotation/freezed_annotation.dart";
part "space_edge.freezed.dart";
part "space_edge.g.dart";

@freezed
abstract class SpaceEdge with _$SpaceEdge {
  const factory SpaceEdge({
    required String childId,
    @Default(false) bool suggested,
  }) = _SpaceEdge;

  factory SpaceEdge.fromJson(Map<String, Object?> json) =>
      _$SpaceEdgeFromJson(json);
}
