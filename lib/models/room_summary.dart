import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/join_rule.dart";
part "room_summary.freezed.dart";
part "room_summary.g.dart";

@freezed
abstract class RoomSummary with _$RoomSummary {
  const factory RoomSummary({
    required String roomId,
    @JsonKey(name: "num_joined_members") required int joinedMembers,
    JoinRule? joinRule,
    String? name,
    Uri? avatarUrl,
    String? canonicalAlias,
    String? topic,
    String? roomVersion,
    @JsonKey(unknownEnumValue: RoomType.room) RoomType? roomType,
  }) = _RoomSummary;

  factory RoomSummary.fromJson(Map<String, Object?> json) =>
      _$RoomSummaryFromJson(json);
}
