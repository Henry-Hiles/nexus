import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_popover.dart";
import "package:nexus/widgets/user_bottom_sheet.dart";

extension ShowUserPopover on BuildContext {
  void showUserPopover(String userId, {String? roomId, Rect? anchor}) =>
      showAdaptivePopover(
        (context) => UserBottomSheet(userId, roomId: roomId),
        anchor: anchor,
      );
}
