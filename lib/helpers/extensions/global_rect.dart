import "package:material_ui/material_ui.dart";

extension GlobalRect on BuildContext {
  /// Where the widget this context belongs to is on screen, e.g. to open a
  /// menu or popover next to it.
  Rect get globalRect {
    final overlay = Overlay.of(this).context.findRenderObject() as RenderBox;

    return switch (findRenderObject()) {
      final RenderBox box =>
        box.localToGlobal(.zero, ancestor: overlay) & box.size,
      _ => Rect.zero,
    };
  }
}
