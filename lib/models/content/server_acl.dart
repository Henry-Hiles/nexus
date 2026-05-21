import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "server_acl.freezed.dart";
part "server_acl.g.dart";

@freezed
abstract class ServerACLContent extends Content with _$ServerACLContent {
  ServerACLContent._();
  factory ServerACLContent({
    @Default(IList.empty()) IList<String> allow,
    @Default(IList.empty()) IList<String> deny,
    @Default(true) allowIpLiterals,
  }) = _ServerACLContent;

  factory ServerACLContent.fromJson(Map<String, Object?> json) =>
      _$ServerACLContentFromJson(json);
}
