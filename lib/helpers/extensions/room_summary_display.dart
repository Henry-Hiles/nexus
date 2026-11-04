import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/room_summary.dart";

extension RoomSummaryDisplay on RoomSummary {
  bool get isSpace => roomType == RoomType.space;

  IconData get icon => isSpace ? Icons.workspaces : Icons.numbers;

  String get displayName =>
      name ?? canonicalAlias ?? (isSpace ? "Unnamed Space" : "Unnamed Room");

  /// E.g. "Space · 12 members"
  String get details => [
    if (isSpace) "Space",
    if (joinedMembers case final members?) "$members members",
  ].join(" · ");
}
