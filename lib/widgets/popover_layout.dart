import "dart:math";

import "package:material_ui/material_ui.dart";

/// Positions a popover below [anchor], or above it if there isn't room below,
/// keeping it fully on screen.
class const PopoverLayout(final Rect anchor) extends SingleChildLayoutDelegate {
  static const margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().deflate(const .all(margin));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final fitsBelow = anchor.bottom + childSize.height + margin <= size.height;

    return .new(
      anchor.left.clamp(
        margin,
        max(margin, size.width - childSize.width - margin),
      ),
      (fitsBelow ? anchor.bottom : anchor.top - childSize.height).clamp(
        margin,
        max(margin, size.height - childSize.height - margin),
      ),
    );
  }

  @override
  bool shouldRelayout(PopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}
