import "package:flutter/material.dart";
import "package:nexus/widgets/divider_widget.dart";

class DividerText extends StatelessWidget {
  final String text;

  const DividerText(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      DividerWidget(Text(text, style: Theme.of(context).textTheme.labelLarge));
}
