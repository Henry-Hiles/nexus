import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/join_rule.dart";

part "room_summary.freezed.dart";
part "room_summary.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RoomSummary({
  required final String roomId,
  @JsonKey(name: "num_joined_members") required final int joinedMembers,
  final JoinRule? joinRule,
  final String? name,
  final Uri? avatarUrl,
  final String? canonicalAlias,
  final String? topic,
  final String? roomVersion,
  @JsonKey(unknownEnumValue: RoomType.room) final RoomType? roomType,
}) with _$RoomSummary {
  Map<String, Object?> toJson() => _$RoomSummaryToJson(this);

  factory RoomSummary.fromJson(Map<String, Object?> json) =>
      _$RoomSummaryFromJson(json);
}
