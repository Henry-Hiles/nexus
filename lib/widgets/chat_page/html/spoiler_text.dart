import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";

class SpoilerText extends HookWidget {
  final String text;

  const SpoilerText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final revealed = useState(false);

    return InlineCustomWidget(
      child: InkWell(
        onTap: () => revealed.value = !revealed.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: revealed.value ? Colors.transparent : Colors.blueGrey,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            text,
            style: TextStyle(color: revealed.value ? null : Colors.transparent),
          ),
        ),
      ),
    );
  }
}
