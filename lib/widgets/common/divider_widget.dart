import "package:material_ui/material_ui.dart";

final class const DividerWidget(final Widget widget, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => Row(
      children: [
        SizedBox(
          width: 16,
          child: Divider(color: Theme.of(context).colorScheme.onSurface),
        ),
        ConstrainedBox(
          constraints: .new(maxWidth: constraints.maxWidth - 32),
          child: Padding(padding: const .all(8), child: widget),
        ),
        Expanded(
          child: Divider(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    ),
  );
}
