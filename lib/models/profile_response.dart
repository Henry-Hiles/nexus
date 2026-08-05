import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/membership.dart";
part "profile_response.freezed.dart";
part "profile_response.g.dart";

@freezed
abstract class ProfileResponse with _$ProfileResponse {
  const factory ProfileResponse({
    @JsonKey(fromJson: Profile.fromJson) required Profile profile,
    required Bio? bio,
  }) = _ProfileResponse;

  factory ProfileResponse.fromJson(Map<String, Object?> json) =>
      _$ProfileResponseFromJson(json);
}

@freezed
abstract class Bio with _$Bio {
  const factory Bio({required String html, String? editSource}) = _Bio;

  factory Bio.fromJson(Map<String, Object?> json) => _$BioFromJson(json);
}

@freezed
abstract class Profile with _$Profile {
  static Object? readPronouns(Map<dynamic, dynamic> map, String key) =>
      map[key] ?? map["io.fsky.nyx.pronouns"];

  static Object? readTimezone(Map<dynamic, dynamic> map, String key) =>
      map[key] ?? map["us.cloke.msc4175.tz"];

  const factory Profile({
    String? id,
    String? parseError,
    Uri? avatarUrl,

    @JsonKey(
      name: "displayname",
      fromJson: MembershipContent.displaynameFromJson,
    )
    String? displayName,

    @JsonKey(readValue: Profile.readTimezone, name: "m.tz") String? timezone,

    @Default(IList.empty())
    @JsonKey(readValue: Profile.readPronouns, name: "m.pronouns")
    IList<Pronoun> pronouns,
  }) = _Profile;

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

@freezed
abstract class Pronoun with _$Pronoun {
  const factory Pronoun({required String language, required String summary}) =
      _Pronoun;

  factory Pronoun.fromJson(Map<String, Object?> json) =>
      _$PronounFromJson(json);
}
