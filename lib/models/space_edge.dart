import "package:freezed_annotation/freezed_annotation.dart";

part "space_edge.freezed.dart";
part "space_edge.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SpaceEdge({
  required final String childId,
  final bool suggested = false,
}) with _$SpaceEdge {
  Map<String, Object?> toJson() => _$SpaceEdgeToJson(this);

  factory SpaceEdge.fromJson(Map<String, Object?> json) =>
      _$SpaceEdgeFromJson(json);
}
