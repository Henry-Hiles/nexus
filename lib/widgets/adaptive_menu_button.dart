import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_menu.dart";

/// Like [PopupMenuButton], but shows a bottom sheet on mobile.
class const AdaptiveMenuButton({
  required final Widget icon,
  required final List<PopupMenuEntry> Function(BuildContext context)
  itemBuilder,
  final String? tooltip,
  final bool enabled = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
    icon: icon,
    tooltip: tooltip,
    onPressed: enabled
        ? () => context.showAdaptiveMenu(itemBuilder(context))
        : null,
  );
}
