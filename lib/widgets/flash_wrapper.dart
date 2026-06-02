import "package:flutter/material.dart";

class FlashWrapper extends StatelessWidget {
  final Widget child;
  final bool isFlashing;
  const FlashWrapper(this.child, {this.isFlashing = false, super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: .all(.circular(12)),
    child: AnimatedContainer(
      padding: isFlashing ? .all(8) : .all(0),
      color: isFlashing
          ? Theme.of(context).colorScheme.onSurface.withAlpha(50)
          : Colors.transparent,
      duration: .new(milliseconds: 250),
      child: child,
    ),
  );
}
