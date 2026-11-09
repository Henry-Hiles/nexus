import "dart:math";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";

/// Three dots that bounce one after another, in a loop.
class const BouncingDots({required final Color color, super.key})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const .new(milliseconds: 1200),
    );
    useEffect(() {
      controller.repeat();
      return null;
    }, []);
    final progress = useAnimation(controller);

    return Row(
      mainAxisSize: .min,
      spacing: 3,
      children: [0, 1, 2].map((index) {
        final phase = (progress - index * 0.15) % 1;
        final bounce = phase < 0.4 ? sin(phase / 0.4 * pi) : 0.0;

        return Transform.translate(
          offset: .new(0, -3 * bounce),
          child: Opacity(
            opacity: 0.4 + 0.6 * bounce,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: .circle),
            ),
          ),
        );
      }).toList(),
    );
  }
}
