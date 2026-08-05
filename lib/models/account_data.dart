import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "account_data.freezed.dart";
part "account_data.g.dart";

@freezed
abstract class AccountData with _$AccountData {
  const AccountData._();
  static List<dynamic>? readRecentEmojiValue(
    Map<dynamic, dynamic> json,
    String key,
  ) => json[key]?["recent_emoji"];

  static Map<String, List<dynamic>>? recentEmojiToJson(
    IList<RecentEmoji> recentEmoji,
  ) => {"recent_emoji": recentEmoji.map((emoji) => emoji.toJson()).toList()};

  const factory AccountData({
    @JsonKey(name: InvitePermissionConfig.key)
    @Default(InvitePermissionConfig())
    InvitePermissionConfig invitePermissionConfig,

    @JsonKey(name: "m.direct")
    @Default(IMap.empty())
    IMap<String, IList<String>> directMessages,

    @JsonKey(
      name: "m.recent_emoji",
      readValue: AccountData.readRecentEmojiValue,
      toJson: AccountData.recentEmojiToJson,
    )
    @Default(IList.empty())
    IList<RecentEmoji> recentEmoji,
  }) = _AccountData;

  factory AccountData.fromJson(Map<String, Object?> json) =>
      _$AccountDataFromJson(json);
}

@freezed
abstract class InvitePermissionConfig with _$InvitePermissionConfig {
  static const key = "m.invite_permission_config";

  const factory InvitePermissionConfig({
    @JsonKey(unknownEnumValue: DefaultInviteAction.allow)
    @Default(DefaultInviteAction.allow)
    DefaultInviteAction defaultAction,
  }) = _InvitePermissionConfig;

  factory InvitePermissionConfig.fromJson(Map<String, Object?> json) =>
      _$InvitePermissionConfigFromJson(json);
}

@freezed
abstract class RecentEmoji with _$RecentEmoji {
  const factory RecentEmoji({required String emoji, required int total}) =
      _RecentEmoji;

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
