import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "canonical_alias.freezed.dart";
part "canonical_alias.g.dart";

@freezed
abstract class CanonicalAliasContent extends Content
    with _$CanonicalAliasContent {
  CanonicalAliasContent._();
  factory CanonicalAliasContent({
    String? alias,
    @Default(ISet.empty()) ISet<String> altAliases,
  }) = _CanonicalAliasContent;

  factory CanonicalAliasContent.fromJson(Map<String, Object?> json) =>
      _$CanonicalAliasContentFromJson(json);
}
