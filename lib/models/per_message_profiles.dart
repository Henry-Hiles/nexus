import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "per_message_profiles.freezed.dart";
part "per_message_profiles.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const PerMessageProfiles({
  final String? defaultProfileId,
  final IList<StoredProfile> profiles = const .empty(),
}) with _$PerMessageProfiles {
  StoredProfile? byId(String? id) =>
      profiles.firstWhereOrNull((profile) => profile.id == id);

  Map<String, Object?> toJson() => _$PerMessageProfilesToJson(this);

  factory PerMessageProfiles.fromJson(Map<String, Object?> json) =>
      _$PerMessageProfilesFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const StoredProfile({
  required final String id,
  @JsonKey(name: "displayname") final String? displayName,
  final Uri? avatarUrl,
  final IList<ProfileTrigger> triggers = const .empty(),
}) with _$StoredProfile {
  Map<String, Object?> toJson() => _$StoredProfileToJson(this);

  factory StoredProfile.fromJson(Map<String, Object?> json) =>
      _$StoredProfileFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const ProfileTrigger({
  final String prefix = "",
  final String suffix = "",
  final bool keepTrigger = false,
}) with _$ProfileTrigger {
  Map<String, Object?> toJson() => _$ProfileTriggerToJson(this);

  factory ProfileTrigger.fromJson(Map<String, Object?> json) =>
      _$ProfileTriggerFromJson(json);
}
