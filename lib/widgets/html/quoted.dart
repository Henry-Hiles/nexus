import "package:material_ui/material_ui.dart";

class const Quoted(final Widget child, {super.key}) extends StatelessWidget {
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
