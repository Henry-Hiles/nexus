import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/widgets/users/user_bottom_sheet.dart";

extension ShowUserPopover on BuildContext {
  void showUserPopover(String userId, {String? roomId, Rect? anchor}) =>
      showAdaptivePopover(
        (context) => UserBottomSheet(userId, roomId: roomId),
        anchor: anchor,
      );
}
