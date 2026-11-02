import "package:material_ui/material_ui.dart";

/// Replaces the composer's text field with something to send, like a sticker.
class const ComposerReplacement(
  final Widget child, {
  required final String removeTooltip,
  required final VoidCallback onRemove,
  final FocusOnKeyEventCallback? onKeyEvent,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: onKeyEvent,
    child: Padding(
      padding: .symmetric(vertical: 8),
      child: Row(
        spacing: 12,
        children: [
          Expanded(child: child),
          IconButton(
            tooltip: removeTooltip,
            onPressed: onRemove,
            icon: Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}
