import "package:material_ui/material_ui.dart";

extension ShowContextMenu on BuildContext {
  void showContextMenu({
    required Offset globalPosition,
    required List<PopupMenuEntry> children,
  }) {
    final overlay = Overlay.of(this).context.findRenderObject() as RenderBox;

    showMenu(
      context: this,
      constraints: .loose(Size.infinite),
      position: .fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: children,
    );
  }
}
