import "package:material_ui/material_ui.dart";

final class const HighlightWrapper(
  final Widget child, {
  final bool isHighlighted = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: .all(.circular(12)),
    child: AnimatedContainer(
      padding: isHighlighted ? .all(8) : .all(0),
      color: isHighlighted
          ? Theme.of(context).colorScheme.onSurface.withAlpha(50)
          : Colors.transparent,
      duration: .new(milliseconds: 250),
      child: Material(color: Colors.transparent, child: child),
    ),
  );
}
