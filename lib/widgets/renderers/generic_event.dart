import "package:flutter/material.dart";

class GenericEventRenderer extends StatelessWidget {
  final IconData icon;
  final List<Widget> children;
  const GenericEventRenderer(this.icon, this.children, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      spacing: 8,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.people),
        ),
        Expanded(child: Wrap(spacing: 4, children: children)),
      ],
    ),
  );
}
