import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class const Spoiler(final Widget child, {super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final revealed = useState(false);

    return InkWell(
      onTap: () => revealed.value = !revealed.value,
      child: AnimatedContainer(
        duration: Durations.short2,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.3),
          borderRadius: .circular(4),
        ),
        foregroundDecoration: BoxDecoration(
          color: revealed.value ? Colors.transparent : Colors.blueGrey,
          borderRadius: .circular(4),
        ),
        child: IgnorePointer(ignoring: !revealed.value, child: child),
      ),
    );
  }
}
