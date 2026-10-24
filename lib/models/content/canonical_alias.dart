import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "canonical_alias.freezed.dart";
part "canonical_alias.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const CanonicalAliasContent({
  @JsonKey(includeIfNull: false) final String? alias,
  final ISet<String> altAliases = const .empty(),
}) extends Content with _$CanonicalAliasContent {
  factory CanonicalAliasContent.fromJson(Map<String, Object?> json) =>
      _$CanonicalAliasContentFromJson(json);
}
