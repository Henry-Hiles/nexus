import "package:flutter/material.dart";

class HighlightWrapper extends StatelessWidget {
  final Widget child;
  final bool isHighlighted;
  const HighlightWrapper(this.child, {this.isHighlighted = false, super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: .all(.circular(12)),
    child: AnimatedContainer(
      padding: isHighlighted ? .all(8) : .all(0),
      color: isHighlighted
          ? Theme.of(context).colorScheme.onSurface.withAlpha(50)
          : Colors.transparent,
      duration: .new(milliseconds: 250),
      child: child,
    ),
  );
}
