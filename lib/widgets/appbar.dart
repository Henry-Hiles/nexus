import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/settings.dart";
import "package:window_manager/window_manager.dart";

final class const Appbar({
  final Widget? leading,
  final Widget? title,
  final Color? backgroundColor,
  final double? scrolledUnderElevation,
  final IList<Widget> actions = const .empty(),
  final VoidCallback? onTap,
  super.key,
}) extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const .fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> maximize() async {
      final isMaximized = await windowManager.isMaximized();

      if (isMaximized) {
        return windowManager.unmaximize();
      }

      return windowManager.maximize();
    }

    return GestureDetector(
      onPanStart: ref
          .watch(SettingsController.provider)
          .whenOrNull(
            data: (settings) => settings.linuxMobileMode
                ? null
                : (_) => windowManager.startDragging(),
          ),
      child: AppBar(
        leading: InkWell(onTap: onTap, child: leading),
        backgroundColor: backgroundColor,
        scrolledUnderElevation: scrolledUnderElevation,
        actionsPadding: const .symmetric(horizontal: 8),
        title: InkWell(
          onTap: onTap,
          child: IgnorePointer(child: title),
        ),
        flexibleSpace: GestureDetector(onDoubleTap: maximize),
        actions: [
          ...actions,
          if (!(Platform.isAndroid || Platform.isIOS)) ...[
            if (!Platform.isLinux)
              IconButton(
                tooltip: "Maximize window",
                onPressed: maximize,
                icon: const Icon(Icons.fullscreen),
              ),
            IconButton(
              tooltip: "Close window",
              onPressed: () => exit(0),
              icon: const Icon(Icons.close),
            ),
          ],
        ],
      ),
    );
  }
}
