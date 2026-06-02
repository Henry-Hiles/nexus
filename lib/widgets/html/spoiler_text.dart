import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class SpoilerText extends HookWidget {
  final String text;

  const SpoilerText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final revealed = useState(false);

    return InkWell(
      onTap: () => revealed.value = !revealed.value,
      child: AnimatedContainer(
        duration: const .new(milliseconds: 100),
        padding: const .symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: revealed.value ? Colors.transparent : Colors.blueGrey,
          borderRadius: .circular(4),
        ),
        child: Text(
          text,
          style: .new(color: revealed.value ? null : Colors.transparent),
        ),
      ),
    );
  }
}
