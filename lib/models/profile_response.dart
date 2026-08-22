import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/membership.dart";

part "profile_response.freezed.dart";
part "profile_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ProfileResponse({
  @JsonKey(fromJson: Profile.fromJson) required final Profile profile,
  required final Bio? bio,
}) with _$ProfileResponse {
  Map<String, Object?> toJson() => _$ProfileResponseToJson(this);

  factory ProfileResponse.fromJson(Map<String, Object?> json) =>
      _$ProfileResponseFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Bio({required final String html, final String? editSource})
    with _$Bio {
  Map<String, Object?> toJson() => _$BioToJson(this);

  factory Bio.fromJson(Map<String, Object?> json) => _$BioFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Profile({
  final String? id,
  final String? parseError,
  final Uri? avatarUrl,

  @JsonKey(name: "displayname", fromJson: MembershipContent.displaynameFromJson)
  final String? displayName,

  @JsonKey(readValue: Profile.readTimezone, name: "m.tz")
  final String? timezone,

  @JsonKey(readValue: Profile.readPronouns, name: "m.pronouns")
  final IList<Pronoun> pronouns = const IList.empty(),
}) with _$Profile {
  Map<String, Object?> toJson() => _$ProfileToJson(this);

  static Object? readPronouns(Map<dynamic, dynamic> map, String key) =>
      map[key] ?? map["io.fsky.nyx.pronouns"];

  static Object? readTimezone(Map<dynamic, dynamic> map, String key) =>
      map[key] ?? map["us.cloke.msc4175.tz"];

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  factory Profile.fromJsonWithCatch(Map<String, dynamic> json) {
    try {
      return Profile.fromJson(json);
    } catch (error) {
      return _Profile(parseError: error.toString());
    }
  }
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Pronoun({
  required final String language,
  required final String summary,
}) with _$Pronoun {
  Map<String, Object?> toJson() => _$PronounToJson(this);

  factory Pronoun.fromJson(Map<String, Object?> json) =>
      _$PronounFromJson(json);
}
