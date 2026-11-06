import "package:material_ui/material_ui.dart";

extension RefocusAfterRebuild on FocusNode {
  /// Focuses this again once the text field using it has been replaced.
  void refocusAfterRebuild() {
    unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => requestFocus());
  }
}
