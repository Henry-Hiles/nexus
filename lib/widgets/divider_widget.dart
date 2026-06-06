import "package:flutter/material.dart";

class DividerWidget extends StatelessWidget {
  final Widget widget;
  const DividerWidget(this.widget, {super.key});

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
