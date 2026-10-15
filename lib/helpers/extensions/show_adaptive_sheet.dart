import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";

extension ShowAdaptiveSheet on BuildContext {
  /// Shows the widget from [builder] in a dialog on desktop, or a bottom sheet
  /// on mobile. Use the context passed to [builder] to close it.
  Future<void> showAdaptiveSheet(WidgetBuilder builder) => isDesktop
      ? showDialog(
          context: this,
          builder: (context) => Dialog(
            clipBehavior: .antiAlias,
            child: ConstrainedBox(
              constraints: const .new(maxWidth: 450, maxHeight: 600),
              child: Builder(builder: builder),
            ),
          ),
        )
      : showModalBottomSheet(
          context: this,
          isScrollControlled: true,
          constraints: .new(maxHeight: MediaQuery.sizeOf(this).height - 80),
          builder: builder,
        );
}
