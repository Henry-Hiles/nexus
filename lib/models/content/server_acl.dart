import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "server_acl.freezed.dart";
part "server_acl.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ServerACLContent({
  final IList<String> allow = const .empty(),
  final IList<String> deny = const .empty(),
  final bool allowIpLiterals = true,
}) extends Content with _$ServerACLContent {
  factory ServerACLContent.fromJson(Map<String, Object?> json) =>
      _$ServerACLContentFromJson(json);
}
