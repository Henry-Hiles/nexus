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
  final IMap<String, IList<String>> directMessages = const IMap.empty(),

  @JsonKey(
    name: AccountData.recentEmojiKey,
    readValue: AccountData.readRecentEmojiValue,
    toJson: AccountData.recentEmojiToJson,
  )
  final IList<RecentEmoji> recentEmoji = const IList.empty(),
}) with _$AccountData {
  static List<dynamic>? readRecentEmojiValue(
    Map<dynamic, dynamic> json,
    String key,
  ) => json[key]?["recent_emoji"];

  static Map<String, List<dynamic>>? recentEmojiToJson(
    IList<RecentEmoji> recentEmoji,
  ) => {"recent_emoji": recentEmoji.map((emoji) => emoji.toJson()).toList()};

  static const invitePermissionConfigKey = "m.invite_permission_config";
  static const directKey = "m.direct";
  static const recentEmojiKey = "m.recent_emoji";

  Map<String, Object?> toJson() => _$AccountDataToJson(this);

  factory AccountData.fromJson(Map<String, Object?> json) =>
      _$AccountDataFromJson(json);
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
