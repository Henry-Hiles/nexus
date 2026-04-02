import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "profile.freezed.dart";
part "profile.g.dart";

Object? readPronouns(Map<dynamic, dynamic> map, _) =>
    map["m.pronouns"] ?? map["io.fsky.nyx.pronouns"];

Object? readTimezone(Map<dynamic, dynamic> map, _) =>
    map["m.tz"] ?? map["us.cloke.msc4175.tz"];

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    String? avatarUrl,
    @JsonKey(name: "displayname") String? displayName,

    @JsonKey(readValue: readTimezone) String? timezone,

    @Default(IList.empty())
    @JsonKey(readValue: readPronouns)
    IList<Pronoun> pronouns,
  }) = _Profile;

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);
}

@freezed
abstract class Pronoun with _$Pronoun {
  const factory Pronoun({required String language, required String summary}) =
      _Pronoun;

  factory Pronoun.fromJson(Map<String, Object?> json) =>
      _$PronounFromJson(json);
}
