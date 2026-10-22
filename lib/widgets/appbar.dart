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

  /// Whether to show the minimize, maximize and close buttons on desktop.
  final bool windowControls = true,
  super.key,
}) extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const .fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void maximize() {
      final window = WindowManager.instance.getCurrent();
      if (window == null) return;

      if (window.isMaximized) {
        return window.unmaximize();
      }

      return window.maximize();
    }

    return GestureDetector(
      onPanStart: ref
          .watch(SettingsController.provider)
          .whenOrNull(
            data: (settings) => settings.linuxMobileMode
                ? null
                : (_) => WindowManager.instance.getCurrent()?.startDragging(),
          ),
      child: AppBar(
        leading: leading == null ? null : InkWell(onTap: onTap, child: leading),
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
          if (windowControls && !(Platform.isAndroid || Platform.isIOS)) ...[
            if (ref
                    .watch(SettingsController.provider)
                    .whenOrNull(
                      data: (settings) => settings.showMinimizeButton,
                    ) ??
                false)
              IconButton(
                tooltip: "Minimize window",
                onPressed: () =>
                    WindowManager.instance.getCurrent()?.minimize(),
                icon: const Icon(Icons.minimize),
              ),
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
