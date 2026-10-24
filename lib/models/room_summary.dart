import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/join_rule.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/models/room_metadata.dart";

part "room_summary.freezed.dart";
part "room_summary.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const RoomSummary({
  required final String roomId,
  @JsonKey(name: "num_joined_members") final int? joinedMembers,
  @JsonKey(unknownEnumValue: JoinRule.unknown) final JoinRule? joinRule,

  /// Rooms whose members may join without an invite, for restricted rooms.
  final IList<String> allowedRoomIds = const .empty(),
  final String? name,
  final Uri? avatarUrl,
  final String? canonicalAlias,
  final String? topic,
  final String? roomVersion,
  @JsonKey(unknownEnumValue: RoomType.room) final RoomType? roomType,

  /// The encryption algorithm, if the room is encrypted.
  final String? encryption,
  final bool? worldReadable,

  /// The current user's membership in the room, if any.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final MembershipStatus? membership,

  /// Who invited the current user, for invites.
  @JsonKey(includeFromJson: false) final String? invitedBy,

  /// The reason given for the invite, if any.
  @JsonKey(includeFromJson: false) final String? inviteReason,

  /// The inviter's membership, for their display name and avatar.
  @JsonKey(includeFromJson: false) final MembershipContent? inviterProfile,

  /// Whether this is an invite to a direct message.
  @JsonKey(includeFromJson: false) final bool isDirect = false,
}) with _$RoomSummary {
  /// Whether the user has to knock rather than join, given the rooms they've
  /// joined. Restricted knock rooms can be joined directly from an allowed room.
  bool mustKnock(ISet<String> joinedRooms) => switch (joinRule) {
    .knock => true,
    .knockRestricted => !allowedRoomIds.any(joinedRooms.contains),
    _ => false,
  };

  /// A summary of a room the user is in, from its synced metadata.
  factory RoomSummary.fromMetadata(RoomMetadata metadata) => .new(
    roomId: metadata.id,
    joinedMembers: metadata.lazyLoadSummary?.joinedMemberCount,
    avatarUrl: metadata.avatar,
    canonicalAlias: metadata.canonicalAlias,
    name: metadata.name,
    topic: metadata.topic,
  );

  factory RoomSummary.fromJson(Map<String, Object?> json) =>
      _$RoomSummaryFromJson(json);
}
