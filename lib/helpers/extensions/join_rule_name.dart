import "package:nexus/models/join_rule.dart";

extension JoinRuleName on JoinRule {
  /// What the rule is called in the UI, e.g. "Invite only".
  String get displayName => switch (this) {
    .public => "Public",
    .invite => "Invite only",
    .knock => "Knock",
    .restricted => "Restricted",
    .knockRestricted => "Restricted or knock",
    .private => "Private",
  };
}
