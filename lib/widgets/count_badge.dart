import "package:material_ui/material_ui.dart";

/// Shows [count] in a badge on [child]: nothing if null, a dot if 0, and the
/// number otherwise.
class const CountBadge(
  final int? count, {
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (count) {
    null => child,
    0 => Badge(child: child),
    final count => Badge.count(count: count, child: child),
  };
}
