import "package:flutter/material.dart";

class Quoted extends StatelessWidget {
  final Widget child;
  const Quoted(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border(
        left: .new(width: 4, color: Theme.of(context).dividerColor),
      ),
    ),
    child: Padding(padding: .only(left: 8), child: child),
  );
}
