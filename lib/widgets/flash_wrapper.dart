import "package:flutter/material.dart";

class FlashWrapper extends StatelessWidget {
  final Widget child;
  final bool isFlashing;
  const FlashWrapper(this.child, {this.isFlashing = false, super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    child: AnimatedContainer(
      padding: isFlashing ? EdgeInsets.all(8) : EdgeInsets.all(0),
      color: isFlashing
          ? Theme.of(context).colorScheme.onSurface.withAlpha(50)
          : Colors.transparent,
      duration: Duration(milliseconds: 250),
      child: child,
    ),
  );
}
