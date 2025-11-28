import "package:flutter/material.dart";

extension ShowContextMenu on BuildContext {
  void showContextMenu({
    required Offset globalPosition,
    required VoidCallback onTap,
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
      items: [
        PopupMenuItem(
          onTap: onTap,
          child: ListTile(leading: Icon(Icons.reply), title: Text("Reply")),
        ),
        PopupMenuItem(
          onTap: onTap,
          child: ListTile(leading: Icon(Icons.edit), title: Text("Edit")),
        ),
        PopupMenuItem(
          onTap: onTap,
          child: ListTile(leading: Icon(Icons.delete), title: Text("Delete")),
        ),
      ],
    );
  }
}
