import "package:flutter/material.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";

class MentionChip extends StatelessWidget {
  final String label;
  const MentionChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(
      label.mention ?? label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
    backgroundColor: Theme.of(context).colorScheme.primary,
    onPressed: () => showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Text("TODO: Open room or join room dialog, or user popover"),
      ), // TODO
    ),
  );
}
