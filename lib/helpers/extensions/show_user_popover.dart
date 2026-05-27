import "package:flutter/material.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/user_popover.dart";

extension ShowUserPopover on BuildContext {
  void showUserPopover(
    MembershipContent member,
    String userId, {
    String? roomId,
    required Offset globalPosition,
  }) => showContextMenu(
    globalPosition: globalPosition,
    children: [
      PopupMenuItem(
        enabled: false,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: IconTheme(
          data: IconThemeData(),
          child: UserPopover(member, userId, roomId: roomId),
        ),
      ),
    ],
  );
}
