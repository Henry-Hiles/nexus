import "package:flutter/material.dart";

extension ShowContextMenu on BuildContext {
  void showContextMenu({
    required Offset globalPosition,
    required List<PopupMenuEntry> children,
  }) {
    final overlay = Overlay.of(this).context.findRenderObject() as RenderBox;

    showMenu(
      context: this,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      color: Theme.of(this).colorScheme.surfaceContainerHighest,
      items: children,
    );
  }
}
