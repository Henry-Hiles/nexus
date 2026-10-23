import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "account_data.freezed.dart";
part "account_data.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const AccountData({
  @JsonKey(name: AccountData.invitePermissionConfigKey)
  final InvitePermissionConfig invitePermissionConfig =
      const InvitePermissionConfig(),

  @JsonKey(name: AccountData.directKey)
  final IMap<String, IList<String>> directMessages = const .empty(),

  @JsonKey(name: AccountData.recentEmojiKey)
  final RecentEmojiData recentEmoji = const RecentEmojiData(),

  /// Room image packs the user has enabled everywhere
  @JsonKey(
    name: AccountData.imagePackRoomsKey,
    fromJson: ImagePackRooms.tryFromJson,
  )
  final ImagePackRooms? imagePackRooms,
  @JsonKey(
    name: AccountData.legacyImagePackRoomsKey,
    fromJson: ImagePackRooms.tryFromJson,
  )
  final ImagePackRooms? legacyImagePackRooms,
}) with _$AccountData {
  static const invitePermissionConfigKey = "m.invite_permission_config";
  static const directKey = "m.direct";
  static const recentEmojiKey = "m.recent_emoji";
  static const imagePackRoomsKey = "m.image_pack.rooms";
  static const legacyImagePackRoomsKey = "im.ponies.emote_rooms";

  Map<String, Object?> toJson() => _$AccountDataToJson(this);

  factory AccountData.fromJson(Map<String, Object?> json) =>
      _$AccountDataFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RecentEmojiData({
  final IList<RecentEmoji> recentEmoji = const .empty(),
}) with _$RecentEmojiData {
  Map<String, Object?> toJson() => _$RecentEmojiDataToJson(this);

  factory RecentEmojiData.fromJson(Map<String, Object?> json) =>
      _$RecentEmojiDataFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ImagePackRooms({
  /// Room IDs to the state keys of their enabled packs, each to a (currently
  /// empty) object
  final IMap<String, IMap<String, Map<String, dynamic>>> rooms = const .empty(),
}) with _$ImagePackRooms {
  static ImagePackRooms? tryFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return .fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> toJson() => _$ImagePackRoomsToJson(this);

  factory ImagePackRooms.fromJson(Map<String, Object?> json) =>
      _$ImagePackRoomsFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const InvitePermissionConfig({
  @JsonKey(unknownEnumValue: DefaultInviteAction.allow)
  final DefaultInviteAction defaultAction = DefaultInviteAction.allow,
}) with _$InvitePermissionConfig {
  Map<String, Object?> toJson() => _$InvitePermissionConfigToJson(this);

  factory InvitePermissionConfig.fromJson(Map<String, Object?> json) =>
      _$InvitePermissionConfigFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const RecentEmoji({required final String emoji, required final int total})
    with _$RecentEmoji {
  Map<String, Object?> toJson() => _$RecentEmojiToJson(this);

  factory RecentEmoji.fromJson(Map<String, Object?> json) =>
      _$RecentEmojiFromJson(json);
}

@JsonEnum(fieldRename: .snake)
enum DefaultInviteAction {
  allow,
  deny,
  @JsonValue("uk.timedout.msc4494.deny_public")
  denyPublic,
}
