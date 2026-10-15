import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/user_bottom_sheet.dart";

extension ShowUserPopover on BuildContext {
  void showUserPopover(
    MembershipContent member,
    String userId, {
    String? roomId,
  }) => showAdaptiveSheet(
    (context) => UserBottomSheet(member, userId, roomId: roomId),
  );
}
