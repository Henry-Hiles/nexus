import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";

class const SwipeToReply(
  final Widget child, {
  required final VoidCallback? onSwipe,
  super.key,
}) extends HookWidget {
  static const maxDrag = 64.0;
  static const threshold = 0.75;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: Durations.short4);
    useListenable(controller);

    if (onSwipe == null) return child;

    final progress = controller.value;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final previous = controller.value;
        controller.value = previous + details.primaryDelta! / maxDrag;

        if (previous < threshold && controller.value >= threshold) {
          HapticFeedback.lightImpact();
        }
      },
      onHorizontalDragEnd: (_) {
        if (controller.value >= threshold) onSwipe!();
        controller.animateBack(0, curve: Curves.easeOut);
      },
      onHorizontalDragCancel: () =>
          controller.animateBack(0, curve: Curves.easeOut),
      child: Stack(
        alignment: .centerLeft,
        children: [
          Positioned(
            left: 16,
            child: Opacity(
              opacity: (progress / threshold).clamp(0, 1),
              child: Transform.scale(
                scale: progress >= threshold ? 1 : 0.75,
                child: const Icon(Icons.reply),
              ),
            ),
          ),
          Transform.translate(
            offset: .new(progress * maxDrag, 0),
            child: child,
          ),
        ],
      ),
    );
  }
}
