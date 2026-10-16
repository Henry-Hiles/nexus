import "package:material_ui/material_ui.dart";

/// Overrides a text field's paste, to paste files and images with
/// [pasteFiles], falling back to pasting text if it returns false.
class PasteFilesAction(final Future<bool> Function() pasteFiles)
    extends Action<PasteTextIntent> {
  @override
  Future<void> invoke(PasteTextIntent intent) async {
    final pasteText = callingAction;
    if (!await pasteFiles()) pasteText?.invoke(intent);
  }
}
