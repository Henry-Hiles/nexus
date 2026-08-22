import "package:material_ui/material_ui.dart";

class const GenericEventRenderer(
  final IconData icon,
  final List<Widget> children, {
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: .symmetric(vertical: 4),
    child: Row(
      spacing: 8,
      children: [
        Padding(padding: .symmetric(horizontal: 4), child: Icon(icon)),
        Expanded(child: Wrap(spacing: 4, children: children)),
      ],
    ),
  );
}
