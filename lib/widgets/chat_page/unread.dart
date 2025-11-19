import "package:flutter/material.dart";

class Unread extends StatelessWidget {
  final bool isUnread;
  final Widget child;
  const Unread({required this.isUnread, required this.child, super.key});

  @override
  Widget build(BuildContext context) => Badge(
    smallSize: 8,
    backgroundColor: Theme.of(context).colorScheme.primary,
    isLabelVisible: isUnread,
    child: child,
  );
}
