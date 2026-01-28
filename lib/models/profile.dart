import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "profile.freezed.dart";
part "profile.g.dart";

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    String? avatarUrl,
    @JsonKey(name: "displayname") String? displayName,
    @JsonKey(name: "us.cloke.msc4175.tz") String? timezone,

    @Default(IList.empty())
    @JsonKey(name: "io.fsky.nyx.pronouns")
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
