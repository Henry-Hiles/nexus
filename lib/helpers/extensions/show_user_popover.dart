import "package:flutter/material.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/user_bottom_sheet.dart";

extension ShowUserPopover on BuildContext {
  void showUserPopover(
    MembershipContent member,
    String userId, {
    String? roomId,
  }) => showModalBottomSheet(
    constraints: BoxConstraints.loose(
      Size(500, View.of(this).physicalSize.height - 80),
    ),
    isScrollControlled: true,
    context: this,
    builder: (context) => UserBottomSheet(member, userId, roomId: roomId),
  );
}
