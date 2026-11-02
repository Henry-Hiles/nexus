import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";

part "space_child.freezed.dart";
part "space_child.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const SpaceChildContent({
  final IList<String> via = const .empty(),
  final String? order,
  final bool suggested = false,
}) extends Content with _$SpaceChildContent {
  @override
  Map<String, Object?> toJson() => _$SpaceChildContentToJson(this);

  factory SpaceChildContent.fromJson(Map<String, Object?> json) =>
      _$SpaceChildContentFromJson(json);
}
