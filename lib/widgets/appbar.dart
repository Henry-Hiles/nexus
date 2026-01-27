import "dart:io";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:window_manager/window_manager.dart";

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final Color? backgroundColor;
  final double? scrolledUnderElevation;
  final IList<Widget> actions;

  const Appbar({
    super.key,
    this.title,
    this.backgroundColor,
    this.scrolledUnderElevation,
    this.leading,
    this.actions = const IList.empty(),
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Future<void> maximize() async {
      final isMaximized = await windowManager.isMaximized();

      if (isMaximized) {
        return windowManager.unmaximize();
      }

      return windowManager.maximize();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: maximize,
      onPanStart: (_) => windowManager.startDragging(),
      child: AppBar(
        leading: leading,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: scrolledUnderElevation,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: title,
        actions: [
          ...actions,
          if (!(Platform.isAndroid || Platform.isIOS)) ...[
            if (!Platform.isLinux)
              IconButton(
                onPressed: maximize,
                icon: const Icon(Icons.fullscreen),
              ),
            IconButton(onPressed: () => exit(0), icon: const Icon(Icons.close)),
          ],
        ],
      ),
    );
  }
}
