import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";

extension ShowAdaptiveMenu on BuildContext {
  /// Shows [items] in a popup menu on desktop, or a bottom sheet on mobile.
  ///
  /// On desktop, the menu opens at [globalPosition] if given (e.g. where the
  /// user right clicked), or over the widget this context belongs to.
  Future<void> showAdaptiveMenu(
    List<PopupMenuEntry> items, {
    Offset? globalPosition,
  }) async {
    if (!isDesktop) {
      await showModalBottomSheet(
        context: this,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const .only(bottom: 8),
            // PopupMenuItems must be inside something with the menu role
            child: Semantics(
              role: .menu,
              explicitChildNodes: true,
              child: ListTileTheme.merge(
                contentPadding: const .symmetric(horizontal: 24),
                minTileHeight: 48,
                titleTextStyle: Theme.of(context).textTheme.titleMedium,
                child: Column(mainAxisSize: .min, children: items),
              ),
            ),
          ),
        ),
      );
      return;
    }

    final overlay = Overlay.of(this).context.findRenderObject() as RenderBox;
    final anchor = switch (globalPosition) {
      final position? => position & Size.zero,
      null => switch (findRenderObject()) {
        final RenderBox box =>
          box.localToGlobal(.zero, ancestor: overlay) & box.size,
        _ => Rect.zero,
      },
    };

    await showMenu(
      context: this,
      constraints: .loose(.infinite),
      position: .fromRect(anchor, Offset.zero & overlay.size),
      items: items,
    );
  }
}
