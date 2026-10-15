import "package:material_ui/material_ui.dart";

extension IsDesktop on BuildContext {
  /// Whether the window is wide enough for the desktop layout, with the
  /// sidebar always visible, menus instead of bottom sheets, etc.
  bool get isDesktop => MediaQuery.sizeOf(this).width > 650;
}
