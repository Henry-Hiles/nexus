import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/membership.dart";

part "profile_response.freezed.dart";
part "profile_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ProfileResponse({
  @JsonKey(fromJson: Profile.fromJson) required final Profile profile,
  final Bio? bio,
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
  @JsonKey(name: Profile.avatarUrlKey) final Uri? avatarUrl,

  @JsonKey(
    name: Profile.displayNameKey,
    fromJson: MembershipContent.displaynameFromJson,
  )
  final String? displayName,

  @JsonKey(name: Profile.timezoneKey) final String? timezone,

  @JsonKey(readValue: Profile.readPronouns, name: Profile.pronounsKey)
  final IList<Pronoun> pronouns = const .empty(),
}) with _$Profile {
  static const avatarUrlKey = "avatar_url";
  static const displayNameKey = "displayname";
  static const timezoneKey = "m.tz";
  static const pronounsKey = "m.pronouns";
  static const unstablePronounsKey = "io.fsky.nyx.pronouns";

  Map<String, Object?> toJson() => _$ProfileToJson(this);

  Profile withPronouns(String language, Iterable<String> summaries) => copyWith(
    pronouns: pronouns
        .where((pronoun) => pronoun.language != language)
        .toIList()
        .addAll(
          summaries.map(
            (summary) => Pronoun(language: language, summary: summary),
          ),
        ),
  );

  static Object? readPronouns(Map<dynamic, dynamic> map, String key) =>
      /* until stable, commented out:  map[key] ?? */ map[Profile
          .unstablePronounsKey];

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  factory Profile.fromJsonWithCatch(Map<String, dynamic> json) {
    try {
      return Profile.fromJson(json);
    } catch (error) {
      return Profile(parseError: error.toString());
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
