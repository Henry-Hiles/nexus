import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/membership.dart";
part "profile.freezed.dart";
part "profile.g.dart";

@freezed
abstract class Profile with _$Profile {
  static Object? readPronouns(Map<dynamic, dynamic> map, _) =>
      map["m.pronouns"] ?? map["io.fsky.nyx.pronouns"];

  static Object? readTimezone(Map<dynamic, dynamic> map, _) =>
      map["m.tz"] ?? map["us.cloke.msc4175.tz"];

  const factory Profile({
    required String id,
    String? parseError,
    Uri? avatarUrl,

    @JsonKey(
      name: "displayname",
      fromJson: MembershipContent.displaynameFromJson,
    )
    String? displayName,

    @JsonKey(readValue: Profile.readTimezone, name: "m.tz") String? timezone,

    @Default(IList.empty())
    @JsonKey(readValue: Profile.readPronouns, name: "io.fsky.nyx.pronouns")
    IList<Pronoun> pronouns,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  factory Profile.fromJsonWithCatch(Map<String, dynamic> json) {
    try {
      return Profile.fromJson(json);
    } catch (error) {
      return Profile(id: json["id"], parseError: error.toString());
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
