import "package:flutter/material.dart";

class DividerText extends StatelessWidget {
  final String text;

  const DividerText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        SizedBox(
          width: 16,
          child: Divider(color: Theme.of(context).colorScheme.onSurface),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth - 32),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(text, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        Expanded(
          child: Divider(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    ),
  );
}
