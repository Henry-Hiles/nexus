import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/global_rect.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/popover_layout.dart";

extension ShowAdaptivePopover on BuildContext {
  /// Shows the widget from [builder] in a popover next to the widget this
  /// context belongs to on desktop, or a bottom sheet on mobile. Use the
  /// context passed to [builder] to close it.
  Future<void> showAdaptivePopover(WidgetBuilder builder) {
    if (!isDesktop) return showAdaptiveSheet(builder);

    final anchor = globalRect;

    return showDialog(
      context: this,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => CustomSingleChildLayout(
        delegate: PopoverLayout(anchor),
        child: ConstrainedBox(
          constraints: const .new(maxWidth: 420, maxHeight: 600),
          child: Material(
            elevation: 8,
            clipBehavior: .antiAlias,
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: .circular(16),
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }
}
